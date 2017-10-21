/* ex:ts=4:sw=4:sts=4:et */
/* -*- tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*- */
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

using Gee;

/**
 * General device wrapper.
 */
[DBus (name = "org.mconnect.Device")]
class DeviceDBusProxy : Object {

    public string id {
        get {
            return device.device_id;
        }
        private set {
        }
        default = "";
    }
    public string name {
        get {
            return device.device_name;
        }
        private set {
        }
        default = "";
    }
    public string device_type {
        get {
            return device.device_type;
        }
        private set {
        }
        default = "";
    }
    public uint protocol_version {
        get {
            return device.protocol_version;
        }
        private set {
        }
        default = 5;
    }
    public string address {
        get; private set; default = "";
    }

    public bool is_paired {
        get {
            return device.is_paired;
        }
        private set {
        }
        default = false;
    }
    public bool allowed {
        get {
            return device.allowed;
        }
        private set {
        }
        default = false;
    }
    public bool is_active {
        get {
            return device.is_active;
        }
        private set {
        }
        default = false;
    }
    public bool is_connected {
        get; private set; default = false;
    }

    public string[] incoming_capabilities {
        get;
        private set;
    }

    public string[] outgoing_capabilities {
        get;
        private set;
    }

    public string certificate {
        owned get {
            return device.certificate_pem;
        }
        private set {
        }
    }

    public string certificate_fingerprint {
        get {
            return device.certificate_fingerprint;
        }
        private set {
        }
    }

    private HashMap<string, PacketHandlerInterfaceProxy> handlers;

    private uint register_id = 0;

    private DBusPropertyNotifier prop_notifier = null;

    [DBus (visible = false)]
    public ObjectPath object_path = null;

    [DBus (visible = false)]
    public Device device {
        get; private set; default = null;
    }

    public DeviceDBusProxy.for_device_with_path (Device device, ObjectPath path) {
        this.device = device;
        this.object_path = path;
        this.handlers = new HashMap<string, PacketHandlerInterfaceProxy>();
        this.update_address ();
        this.update_capabilities ();
        this.device.notify.connect (this.param_changed);
        this.device.connected.connect (() => {
            this.is_connected = true;
        });
        this.device.disconnected.connect (() => {
            this.is_connected = false;
        });
        this.notify.connect (this.update_properties);
    }

    private void update_capabilities () {
        string[] caps = {};

        foreach (var cap in device.incoming_capabilities) {
            caps += cap;
        }
        this.incoming_capabilities = caps;

        caps = {};

        foreach (var cap in device.outgoing_capabilities) {
            caps += cap;
        }
        this.outgoing_capabilities = caps;
    }

    private void update_address () {
        this.address = "%s:%u".printf (device.host.to_string (),
                                       device.tcp_port);
    }

    private void update_properties (ParamSpec param) {
        debug ("param %s changed", param.name);

        string name = param.name;
        Variant v = null;
        switch (param.name) {
        case "address":
            v = this.address;
            break;
        case "id":
            v = this.id;
            break;
        case "name":
            v = this.name;
            break;
        case "device-type":
            name = "DeviceType";
            v = this.device_type;
            break;
        case "potocol-version":
            name = "ProtocolVersion";
            v = this.protocol_version;
            break;
        case "is-paired":
            name = "IsPaired";
            v = this.is_paired;
            break;
        case "allowed":
            v = this.allowed;
            break;
        case "is-active":
            name = "IsActive";
            v = this.is_active;
            break;
        case "is-connected":
            name = "IsConnected";
            v = this.is_connected;
            break;
        case "certificate":
            name = "certificate";
            v = this.certificate;
            break;
        }

        if (v == null)
            return;

        this.prop_notifier.queue_property_change (name, v);
    }

    private void param_changed (ParamSpec param) {
        debug ("parameter %s changed", param.name);
        switch (param.name) {
        case "host":
        case "tcp-port":
            this.update_address ();
            break;
        case "allowed":
            this.allowed = device.allowed;
            break;
        case "is-active":
            this.is_active = device.is_active;
            break;
        case "is-paired":
            this.is_paired = device.is_paired;
            break;
        case "incoming-capabilities":
        case "outgoing-capabilities":
            this.update_capabilities ();
            break;
        }
    }

    [DBus (visible = false)]
    public bool has_handler (string cap) {
        return this.handlers.has_key (cap);
    }

    [DBus (visible = false)]
    public void bus_register (DBusConnection conn) {
        try {
            this.register_id = conn.register_object (this.object_path, this);
            this.prop_notifier = new DBusPropertyNotifier (conn,
                                                           "org.mconnect.Device",
                                                           this.object_path);
        } catch (IOError err) {
            warning ("failed to register DBus object for device %s under path %s",
                     this.device.to_string (), this.object_path.to_string ());
        }
    }

    [DBus (visible = false)]
    public void bus_unregister (DBusConnection conn) {
        if (this.register_id != 0) {
            conn.unregister_object (this.register_id);
        }
        this.register_id = 0;
        this.prop_notifier = null;
    }

    [DBus (visible = false)]
    public void bus_register_handler (DBusConnection conn,
                                      string cap,
                                      PacketHandlerInterfaceProxy handler) {

        handler.bus_register (conn, this.object_path);
        this.handlers.@set (cap, handler);
    }

    [DBus (visible = false)]
    public void bus_unregister_handler (DBusConnection conn,
                                        string cap) {
        PacketHandlerInterfaceProxy handler;

        this.handlers.@unset (cap, out handler);
        if (handler != null) {
            handler.bus_unregister (conn);
        }
    }
}