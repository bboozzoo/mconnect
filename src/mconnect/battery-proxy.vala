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

[DBus (name = "org.mconnect.Device.Battery")]
class BatteryHandlerProxy : Object, PacketHandlerInterfaceProxy {

	private Device device = null;
	private BatteryHandler battery_handler = null;
	private uint register_id = 0;
	private ulong notify_id = 0;
	private DBusPropertyNotifier prop_notifier = null;

	public uint level { get; private set; default = 0; }
	public bool charging { get; private set; default = false; }

	public BatteryHandlerProxy.for_device_handler(Device dev,
												  PacketHandlerInterface iface) {
		this.device = dev;

		this.battery_handler = (BatteryHandler) iface;

		this.battery_handler.battery.connect(this.battery_change);
	}

	private void battery_change(Device dev, uint level, bool charging) {
		if (this.device != dev)
			return;

		this.level = level;
		this.charging = charging;

		battery(level, charging);
	}

	[DBus (visible = false)]
	public void bus_register(DBusConnection conn, string path) throws IOError {
		if (this.register_id == 0)
			this.register_id = conn.register_object(path, this);

		this.prop_notifier = new DBusPropertyNotifier(conn,
													  "org.mconnect.Device.Battery",
													  path);

		this.notify.connect(this.send_property_change);
	}

	[DBus (visible = false)]
	public void bus_unregister(DBusConnection conn) throws IOError {
		if (this.register_id != 0)
			conn.unregister_object(this.register_id);
		this.register_id = 0;

		this.notify.disconnect(this.send_property_change);
		this.notify_id = 0;
	}

	public signal void battery(uint level, bool charging);

	private void send_property_change(ParamSpec p) {
		assert(this.prop_notifier != null);

		Variant v = null;

		if (p.name == "level") {
			v = this.level;
		}
		if (p.name == "charging") {
			v = this.charging;
		}

		if (v == null)
			return;

		this.prop_notifier.queue_property_change(p.name, v);
	}
}