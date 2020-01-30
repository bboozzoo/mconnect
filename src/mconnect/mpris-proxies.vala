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
 * Raphael Vogelgsang <rap.vog (at] gmail.com>
 */

[DBus (name = "org.freedesktop.DBus")]
public interface DBusProxy : Object {

    public abstract string[] list_names () throws Error;

    public signal void name_owner_changed (string name, string old_owner, string new_owner);
}

[DBus (name = "org.freedesktop.DBus.Properties")]
public interface DBusPropertiesProxy : Object {

    public signal void properties_changed (string interface_name, HashTable<string, Variant> changed_properties, string[] invalidated_properties);
}

[DBus (name = "org.mpris.MediaPlayer2.Player")]
public interface MprisPlayerProxy : Object {

    public abstract void next () throws Error;
    public abstract void previous () throws Error;
    public abstract void play_pause () throws Error;
    public abstract void seek (int64 Offset) throws Error;

    public abstract string playback_status {
        owned get;
    }
    public abstract HashTable<string, Variant> metadata {
        owned get;
    }
    public abstract double volume {
        get; set;
    }
    public abstract int64 position {
        get;
    }
    public abstract bool can_go_next {
        get;
    }
    public abstract bool can_go_previous {
        get;
    }
    public abstract bool can_play {
        get;
    }
    public abstract bool can_pause {
        get;
    }
    public abstract bool can_seek {
        get;
    }
    public abstract bool can_control {
        get;
    }
}

[DBus (name = "org.mpris.MediaPlayer2")]
public interface MprisProxy : Object {

    public abstract string identity {
        owned get;
    }
}
