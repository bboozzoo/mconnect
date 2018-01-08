/**
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * AUTHORS
 * Maciek Borzecki <maciek.borzecki (at] gmail.com>
 */

class MprisHandler : Object, PacketHandlerInterface {

    public const string MPRIS = "kdeconnect.mpris.request";
    public const string MPRIS_PKT = "kdeconnect.mpris";

    private DBusProxy ? _dbus_watcher = null;
    private HashTable<string, MprisPropertiesProxy ? > _properties_watchers;
    private HashTable<string, string> player_list;

    private struct Properties {
        int ? volume;
        string ? now_playing;
        string ? title;
        string ? artist;
        string ? album;
        string ? album_art_url;
        int64 ? length;
        bool ? is_playing;
        bool ? can_pause;
        bool ? can_play;
        bool ? can_go_next;
        bool ? can_go_previous;
        bool ? can_seek;
        int64 position;
    }

    private signal void update_status (Packet pkt);

    public void use_device (Device dev) {
        debug ("use device %s for mpris", dev.to_string ());
        dev.message.connect (this.message);
        update_status.connect (dev.send);
    }

    private MprisHandler () {
        _properties_watchers = new HashTable<string, MprisPropertiesProxy ? >(str_hash, str_equal);
        player_list = new HashTable<string, string>(str_hash, str_equal);
        get_player_list ();
    }

    public static MprisHandler instance () {
        return new MprisHandler ();
    }

    public string get_pkt_type () {
        return MPRIS;
    }

    public void release_device (Device dev) {
        debug ("release device %s", dev.to_string ());
        dev.message.disconnect (this.message);
    }

    private void message (Device dev, Packet pkt) {
        if (pkt.pkt_type != MPRIS) {
            return;
        }

        if (pkt.body.has_member ("requestPlayerList") && pkt.body.get_boolean_member ("requestPlayerList")) {
            get_player_list ();
            update_status (make_player_list_packet (player_list));
        }
        if (!pkt.body.has_member ("player")) {
            return;
        }
        var player_id = pkt.body.get_string_member ("player");
        if (!player_list.contains (player_id)) {
            return;
        }
        var bus_name = player_list.get (player_id);
        if (!_properties_watchers.contains (bus_name)) {
            MprisPropertiesProxy prop = Bus.get_proxy_sync (BusType.SESSION, bus_name, "/org/mpris/MediaPlayer2");
            _properties_watchers.insert (bus_name, prop);
            prop.properties_changed.connect ((a, b, c) => {
                properties_changed (player_id, a, b);
            });
        }

        MprisPlayerProxy mpris_player = Bus.get_proxy_sync (BusType.SESSION, bus_name, "/org/mpris/MediaPlayer2");

        if (pkt.body.has_member ("action")) {
            switch (pkt.body.get_string_member ("action")) {
            case "PlayPause":
                mpris_player.play_pause ();
                break;
            case "Previous":
                mpris_player.previous ();
                break;
            case "Next":
                mpris_player.next ();
                break;
            }
        }

        if (pkt.body.has_member ("setVolume")) {
            mpris_player.volume = (int) pkt.body.get_int_member ("setVolume") / 100.0;
        }

        if (pkt.body.has_member ("SetPosition")) {
            int64 pos = pkt.body.get_int_member ("SetPosition") * 1000 - mpris_player.position;
            mpris_player.seek (pos);
        }

        bool update_needed = false;
        Properties prop = {};
        prop.position = mpris_player.position / 1000;
        if (pkt.body.has_member ("Seek")) {
            mpris_player.seek (pkt.body.get_int_member ("Seek"));
            prop.position += pkt.body.get_int_member ("Seek") / 1000;
            update_needed = true;
        }

        int ? volume = null;
        if (pkt.body.has_member ("requestVolume") && pkt.body.get_boolean_member ("requestVolume")) {
            volume = (int) (mpris_player.volume * 100.0);
            update_needed = true;
        }
        if (pkt.body.has_member ("requestNowPlaying") && pkt.body.get_boolean_member ("requestNowPlaying")) {
            if (mpris_player.metadata.contains ("xesam:title")
                && mpris_player.metadata.get ("xesam:title").is_of_type (VariantType.STRING)) {
                prop.title = mpris_player.metadata.get ("xesam:title").get_string ();
            }
            if (mpris_player.metadata.contains ("xesam:artist")
                && mpris_player.metadata.get ("xesam:artist").is_of_type (VariantType.STRING)) {
                prop.artist = mpris_player.metadata.get ("xesam:artist").get_string ();
            }
            if (mpris_player.metadata.contains ("xesam:album")
                && mpris_player.metadata.get ("xesam:artist").is_of_type (VariantType.STRING)) {
                prop.album = mpris_player.metadata.get ("xesam:artist").get_string ();
            }
            if (mpris_player.metadata.contains ("mpris:artUrl")
                && mpris_player.metadata.get ("mpris:artUrl").is_of_type (VariantType.STRING)) {
                prop.album_art_url = mpris_player.metadata.get ("mpris:artUrl").get_string ();
            }
            prop.now_playing = prop.title;
            if (prop.title != null && prop.artist != null) {
                prop.now_playing = prop.artist + " - " + prop.title;
            }
            debug ("now playing: %s", prop.now_playing);
            if (mpris_player.metadata.contains ("mpris:length")
                && mpris_player.metadata.get ("mpris:length").is_of_type (VariantType.INT64)) {
                prop.length = mpris_player.metadata.get ("mpris:length").get_int64 () / 1000;
            }
            update_needed = true;
        }

        if (update_needed) {
            prop.is_playing = mpris_player.playback_status == "Playing";
            prop.can_pause = mpris_player.can_pause;
            prop.can_play = mpris_player.can_play;
            prop.can_go_next = mpris_player.can_go_next;
            prop.can_go_previous = mpris_player.can_go_previous;
            prop.can_seek = mpris_player.can_seek;
            update_status (make_player_prop_packet (player_id, prop));
        }
    }

    private void properties_changed (string player_id, string interface_name, HashTable<string, Variant> changed_properties) {

        debug ("properties changed for mpris player: %s", player_id);
        if (interface_name != "org.mpris.MediaPlayer2.Player") {
            return;
        }
        Properties prop = {};
        bool update_needed = false;
        if (changed_properties.contains ("Volume")) {
            prop.volume = (int) (changed_properties.get ("Volume").get_double () * 100.0);
            update_needed = true;
        }
        if (changed_properties.contains ("Metadata")) {
            Variant metadata = changed_properties.get ("Metadata");
            Variant ? tmp = null;
            tmp = metadata.lookup_value ("xesam:title", VariantType.STRING);
            if (tmp != null) {
                prop.title = tmp.get_string ();
            }
            tmp = metadata.lookup_value ("xesam:artist", VariantType.STRING);
            if (tmp != null) {
                prop.artist = tmp.get_string ();
            }
            tmp = metadata.lookup_value ("xesam:album", VariantType.STRING);
            if (tmp != null) {
                prop.album = tmp.get_string ();
            }
            tmp = metadata.lookup_value ("mpris:artUrl", VariantType.STRING);
            if (tmp != null) {
                prop.album_art_url = tmp.get_string ();
            }
            prop.now_playing = prop.title;
            if (prop.title != null && prop.artist != null) {
                prop.now_playing = prop.artist + " - " + prop.title;
            }
            tmp = metadata.lookup_value ("mpris:length", VariantType.INT64);
            if (tmp != null) {
                prop.length = tmp.get_int64 () / 1000;
            }
            debug ("now playing: %s", prop.now_playing);
            update_needed = true;
        }
        if (changed_properties.contains ("PlaybackStatus")) {
            prop.is_playing = changed_properties.get ("PlaybackStatus").get_string () == "Playing";
            update_needed = true;
        }
        if (changed_properties.contains ("CanPause")) {
            prop.can_pause = changed_properties.get ("CanPause").get_boolean ();
            update_needed = true;
        }
        if (changed_properties.contains ("CanPlay")) {
            prop.can_play = changed_properties.get ("CanPlay").get_boolean ();
            update_needed = true;
        }
        if (changed_properties.contains ("CanGoNext")) {
            prop.can_go_next = changed_properties.get ("CanGoNext").get_boolean ();
            update_needed = true;
        }
        if (changed_properties.contains ("CanGoPrevious")) {
            prop.can_go_previous = changed_properties.get ("CanGoPrevious").get_boolean ();
            update_needed = true;
        }
        if (changed_properties.contains ("CanSeek")) {
            prop.can_seek = changed_properties.get ("CanSeek").get_boolean ();
            update_needed = true;
        }

        if (update_needed) {
            MprisPlayerProxy mpris_player = Bus.get_proxy_sync (BusType.SESSION, "org.mpris.MediaPlayer2.mpv", "/org/mpris/MediaPlayer2");
            prop.position = int64.max (0, mpris_player.position / 1000);
            update_status (make_player_prop_packet (player_id, prop));
        }
    }

    private static Packet make_player_list_packet (HashTable<string, string> player_list) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("playerList");
        builder.begin_array ();
        player_list.foreach ((k, v) => {
            builder.add_string_value (k);
        });
        builder.end_array ();
        builder.end_object ();
        return new Packet (MPRIS_PKT,
                           builder.get_root ().get_object ());
    }

    private static Packet make_player_prop_packet (string player_id, Properties prop) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("player");
        builder.add_string_value (player_id);
        if (prop.volume != null) {
            builder.set_member_name ("volume");
            builder.add_int_value (prop.volume);
        }
        if (prop.now_playing != null) {
            builder.set_member_name ("nowPlaying");
            builder.add_string_value (prop.now_playing);
        }
        if (prop.title != null) {
            builder.set_member_name ("title");
            builder.add_string_value (prop.title);
        }
        if (prop.artist != null) {
            builder.set_member_name ("artist");
            builder.add_string_value (prop.artist);
        }
        if (prop.album != null) {
            builder.set_member_name ("album");
            builder.add_string_value (prop.album);
        }
        if (prop.album_art_url != null) {
            builder.set_member_name ("albumArtUrl");
            builder.add_string_value (prop.album_art_url);
        }
        if (prop.length != null) {
            builder.set_member_name ("length");
            builder.add_int_value (prop.length);
        }
        if (prop.is_playing != null) {
            builder.set_member_name ("isPlaying");
            builder.add_boolean_value (prop.is_playing);
        }
        if (prop.can_pause != null) {
            builder.set_member_name ("canPause");
            builder.add_boolean_value (prop.can_pause);
        }
        if (prop.can_play != null) {
            builder.set_member_name ("canPlay");
            builder.add_boolean_value (prop.can_play);
        }
        if (prop.can_go_next != null) {
            builder.set_member_name ("canGoNext");
            builder.add_boolean_value (prop.can_pause);
        }
        if (prop.can_go_previous != null) {
            builder.set_member_name ("canGoPrevious");
            builder.add_boolean_value (prop.can_pause);
        }
        if (prop.can_seek != null) {
            builder.set_member_name ("canSeek");
            builder.add_boolean_value (prop.can_pause);
        }
        builder.set_member_name ("pos");
        builder.add_int_value (prop.position);
        builder.end_object ();
        return new Packet (MPRIS_PKT,
                           builder.get_root ().get_object ());
    }

    private void add_to_player_list (string bus_name) {
        MprisProxy mpris = Bus.get_proxy_sync (BusType.SESSION,
                                               bus_name,
                                               "/org/mpris/MediaPlayer2");
        player_list.insert (mpris.identity, bus_name);
        debug ("mpris player found: %s", bus_name);
    }

    private void get_player_list () {
        if (_dbus_watcher == null) {
            _dbus_watcher = Bus.get_proxy_sync (BusType.SESSION, "org.freedesktop.DBus", "/org/freedesktop/DBus");

            _dbus_watcher.name_owner_changed.connect ((name, old_owner, new_owner) => {
                if (!name.has_prefix ("org.mpris.MediaPlayer2.")) {
                    return;
                }
                if (new_owner == "") {
                    debug ("mpris player disconnected: %s", name);
                    string key = "";
                    player_list.find ((k, v) => {
                        if (v == name) {
                            key = k;
                        }
                        return v == k;
                    });
                    player_list.remove (key);
                    _properties_watchers.remove (key);
                    update_status (make_player_list_packet (player_list));
                } else if (old_owner == "") {
                    debug ("new mpris player detected: %s", name);
                    add_to_player_list (name);
                    update_status (make_player_list_packet (player_list));
                }
            });
        }

        string[] bus_names = _dbus_watcher.list_names ();

        foreach (string bus_name in bus_names) {
            if (bus_name.has_prefix ("org.mpris.MediaPlayer2.")) {
                add_to_player_list (bus_name);
            }
        }
    }
}