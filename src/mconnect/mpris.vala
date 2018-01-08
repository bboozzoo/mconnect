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

    //TODO: timeout dbus subscription
    private OrgDBus? _db = null;
    private HashTable<string, OrgDBusProperties?> _dbp;
    private HashTable<string, string> player_list;

    private struct Properties {
        int? volume;
        string? now_playing;
        int64? length;
        bool? is_playing;
        bool? can_pause;
        bool? can_play;
        bool? can_go_next;
        bool? can_go_previous;
        bool? can_seek;
        int64 position;
    }

    private signal void update_status (Packet pkt);

    public void use_device (Device dev) {
        debug ("use device %s for mpris", dev.to_string ());
        dev.message.connect (this.message);
        update_status.connect (dev.send);
    }

    private MprisHandler () {
        _dbp =  new HashTable<string, OrgDBusProperties?> (str_hash, str_equal);
        player_list = new HashTable<string, string> (str_hash, str_equal);
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
            update_status (make_player_list_packet(player_list));
        }
        if (!pkt.body.has_member ("player")) {
            return;
        }
        var player_id = pkt.body.get_string_member ("player");
        if (!player_list.contains (player_id)) {
            return;
        }
        var bus_name = player_list.get (player_id);
        if (!_dbp.contains (bus_name)) {
            OrgDBusProperties prop = Bus.get_proxy_sync (BusType.SESSION, bus_name, "/org/mpris/MediaPlayer2");
            _dbp.insert (bus_name, prop);
            prop.properties_changed.connect ((a,b,c) => {
                properties_changed (player_id, a, b);
            });
        }

        OrgMprisPlayer mpris_player = Bus.get_proxy_sync (BusType.SESSION, bus_name, "/org/mpris/MediaPlayer2");

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
            mpris_player.volume = (int)pkt.body.get_int_member ("setVolume")/100.0;
        }

        if (pkt.body.has_member ("SetPosition")) {
            int64 pos = pkt.body.get_int_member ("SetPosition")*1000 - mpris_player.position;
            mpris_player.seek (pos);
        }

        bool update_needed = false;
        int64 position = mpris_player.position/1000;
        if (pkt.body.has_member ("Seek")) {
            mpris_player.seek (pkt.body.get_int_member ("Seek"));
            position += pkt.body.get_int_member ("Seek")/1000;
            update_needed = true;
        }

        int? volume = null;
        if (pkt.body.has_member ("requestVolume") && pkt.body.get_boolean_member ("requestVolume")) {
            volume = (int)(mpris_player.volume*100.0);
            update_needed = true;
        }
        string? now_playing = null;
        int64? length = null;
        if (pkt.body.has_member ("requestNowPlaying") && pkt.body.get_boolean_member ("requestNowPlaying")) {
            extract_metadata(mpris_player.metadata, out now_playing, out length);
            update_needed = true;
        }

        if (update_needed) {
            Properties prop = { volume,
                                now_playing,
                                length,
                                mpris_player.playback_status == "Playing",
                                mpris_player.can_pause,
                                mpris_player.can_play,
                                mpris_player.can_go_next,
                                mpris_player.can_go_previous,
                                mpris_player.can_seek,
                                position};
            update_status (make_player_prop_packet (player_id, prop));
        }
    }

    private void properties_changed (string player_id, string interface_name, HashTable<string, Variant> changed_properties) {

        debug ("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!properties changed %s",interface_name);
        if (interface_name != "org.mpris.MediaPlayer2.Player") {
            return;
        }
        bool update_needed = false;
        int? volume = null;
        if (changed_properties.contains ("Volume")) {
            volume = (int)(changed_properties.get ("Volume").get_double ()*100.0);
            update_needed = true;
        }
        string? now_playing = null;
        int64? length = null;
        if (changed_properties.contains ("Metadata")) {
            HashTable<string, Variant>? metadata = null;
            changed_properties.get ("Metadata").get ("a{sv}", &metadata);
            extract_metadata(metadata, out now_playing, out length);
            update_needed = true;
        }
        bool? playing = null;
        if (changed_properties.contains ("PlaybackStatus")) {
            playing = changed_properties.get ("PlaybackStatus").get_string () == "Playing";
            update_needed = true;
        }
        bool? can_pause = null;
        if (changed_properties.contains ("CanPause")) {
            can_pause = changed_properties.get ("CanPause").get_boolean ();
            update_needed = true;
        }
        bool? can_play = null;
        if (changed_properties.contains ("CanPlay")) {
            can_play = changed_properties.get ("CanPlay").get_boolean ();
            update_needed = true;
        }
        bool? can_go_next = null;
        if (changed_properties.contains ("CanGoNext")) {
            can_go_next = changed_properties.get ("CanGoNext").get_boolean ();
            update_needed = true;
        }
        bool? can_go_previous = null;
        if (changed_properties.contains ("CanGoPrevious")) {
            can_go_previous = changed_properties.get ("CanGoPrevious").get_boolean ();
            update_needed = true;
        }
        bool? can_seek = null;
        if (changed_properties.contains ("CanSeek")) {
            can_seek = changed_properties.get ("CanSeek").get_boolean ();
            update_needed = true;
        }

        if (update_needed) {
            OrgMprisPlayer mpris_player = Bus.get_proxy_sync (BusType.SESSION, "org.mpris.MediaPlayer2.mpv", "/org/mpris/MediaPlayer2");
            Properties prop = { volume,
                                now_playing,
                                length,
                                playing,
                                can_pause,
                                can_play,
                                can_go_next,
                                can_go_previous,
                                can_seek,
                                mpris_player.position/1000};
            update_status (make_player_prop_packet (player_id, prop));
        }
    }

    private void extract_metadata(HashTable<string, Variant> metadata, out string? now_playing, out int64? length) {
        if (metadata.contains ("xesam:title") &&
            metadata.get ("xesam:title").is_of_type (VariantType.STRING)) {
            now_playing = metadata.get ("xesam:title").get_string ();
            if (metadata.contains ("xesam:artist") &&
                metadata.get ("xesam:artist").is_of_type (VariantType.STRING)) {
                now_playing = metadata.get ("xesam:artist").get_string () + " - " + now_playing;
            }
            debug ("now playing: %s", now_playing);
        }
        if (metadata.contains ("mpris:length") &&
            metadata.get ("mpris:length").is_of_type (VariantType.INT64)) {
            length = metadata.get ("mpris:length").get_int64 ()/1000;
        }
    }

    private static Packet make_player_list_packet (HashTable<string, string> player_list) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("playerList");
        builder.begin_array ();
        player_list.foreach ((k,v) => {
            builder.add_string_value (k);
        });
        builder.end_array ();
        builder.end_object ();
        return new Packet (MPRIS_PKT,
                           builder.get_root ().get_object ());
    }

    private static Packet make_player_prop_packet (string player, Properties prop) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("player");
        builder.add_string_value (player);
        if (prop.volume != null) {
            builder.set_member_name ("volume");
            builder.add_int_value (prop.volume);
        }
        if (prop.now_playing != null) {
            builder.set_member_name ("nowPlaying");
            builder.add_string_value (prop.now_playing);
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
        OrgMpris mpris = Bus.get_proxy_sync (BusType.SESSION,
                                             bus_name,
                                             "/org/mpris/MediaPlayer2");
        player_list.insert (mpris.identity, bus_name);
        debug ("mpris player found: %s", bus_name);
    }

    private void get_player_list () {
        if (_db == null) {
            _db = Bus.get_proxy_sync (BusType.SESSION, "org.freedesktop.DBus", "/org/freedesktop/DBus");

            _db.name_owner_changed.connect ((name, old_owner, new_owner) => {
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
                    update_status (make_player_list_packet(player_list));
                } else if (old_owner == "") {
                    debug ("new mpris player detected: %s", name);
                    add_to_player_list (name);
                    update_status (make_player_list_packet (player_list));
                }
            });
        }

        string[] bus_names = _db.list_names ();

        foreach (string bus_name in bus_names) {
            if (bus_name.has_prefix ("org.mpris.MediaPlayer2.")) {
                add_to_player_list (bus_name);
            }
        }
    }
}
