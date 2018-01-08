
[DBus (name = "org.freedesktop.DBus")]
public interface DBusProxy : Object {
    [DBus (name = "ListNames")]
    public abstract string[] list_names () throws DBusError, IOError;

    [DBus (name = "NameOwnerChanged")]
    public signal void name_owner_changed (string name, string old_owner, string new_owner);
}

[DBus (name = "org.freedesktop.DBus.Properties")]
public interface MprisPropertiesProxy : Object {
    [DBus (name = "PropertiesChanged")]
    public signal void properties_changed (string interface_name, HashTable<string, Variant> changed_properties, string[] invalidated_properties);
}

[DBus (name = "org.mpris.MediaPlayer2.Player")]
public interface MprisPlayerProxy : Object {
    [DBus (name = "Next")]
    public abstract void next () throws DBusError, IOError;

    [DBus (name = "Previous")]
    public abstract void previous () throws DBusError, IOError;

    [DBus (name = "PlayPause")]
    public abstract void play_pause () throws DBusError, IOError;

    [DBus (name = "Seek")]
    public abstract void seek (int64 Offset) throws DBusError, IOError;

    [DBus (name = "PlaybackStatus")]
    public abstract string playback_status {
        owned get;
    }
    [DBus (name = "Metadata")]
    public abstract HashTable<string, Variant> metadata {
        owned get;
    }
    [DBus (name = "Volume")]
    public abstract double volume {
        get; set;
    }
    [DBus (name = "Position")]
    public abstract int64 position {
        get;
    }
    [DBus (name = "CanGoNext")]
    public abstract bool can_go_next {
        get;
    }
    [DBus (name = "CanGoPrevious")]
    public abstract bool can_go_previous {
        get;
    }
    [DBus (name = "CanPlay")]
    public abstract bool can_play {
        get;
    }
    [DBus (name = "CanPause")]
    public abstract bool can_pause {
        get;
    }
    [DBus (name = "CanSeek")]
    public abstract bool can_seek {
        get;
    }
    [DBus (name = "CanControl")]
    public abstract bool can_control {
        get;
    }
}

[DBus (name = "org.mpris.MediaPlayer2")]
public interface MprisProxy : Object {
    [DBus (name = "Identity")]
    public abstract string identity {
        owned get;
    }
}