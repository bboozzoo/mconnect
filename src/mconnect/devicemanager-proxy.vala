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

[DBus (name = "org.mconnect.DeviceManager")]
class DeviceManagerDBusProxy : Object
{
	private DeviceManager manager;

	private const string DBUS_PATH = "/org/mconnect/manager";
	private DBusConnection bus = null;
	private HashMap<string, DeviceDBusProxy> devices;

	private int device_idx = 0;

	public DeviceManagerDBusProxy.with_manager(DBusConnection bus,
											   DeviceManager manager) {
		this.manager = manager;
		this.bus = bus;
		this.devices = new HashMap<string, DeviceDBusProxy>();

		manager.found_new_device.connect((d) => {
				this.add_device(d);
			});
		manager.device_capability_added.connect(this.add_device_capability);
	}

	[DBus (visible = false)]
	public void publish() throws IOError {
		assert(this.bus != null);

		this.bus.register_object(DBUS_PATH, this);
	}

	/**
	 * allow_device:
	 * @path: device object path
	 *
	 * Allow given device
	 */
	public void allow_device(string path) {
		debug("allow device %s", path);

		var dev_proxy = this.devices.@get(path);

		if (dev_proxy == null) {
			warning("no device under path %s", path);
			return;
		}

		this.manager.allow_device(dev_proxy.device);
	}

	/**
	 * list_devices:
	 *
	 * Returns a list of DBus paths of all known devices
	 */
	public ObjectPath[] list_devices() {
		ObjectPath[] devices = {};

		foreach (var path in this.devices.keys) {
			devices += new ObjectPath(path);
		}
		return devices;
	}

	private void add_device(Device dev) {
		var path = make_device_path();
		var device_proxy = new DeviceDBusProxy.for_device_with_path(dev,
																	new ObjectPath(path));

		this.devices.@set(path, device_proxy);

		info("register device %s under path %s",
			 dev.to_string(), path);
		device_proxy.bus_register(this.bus);
	}

	private DeviceDBusProxy? find_proxy_for_device(Device dev) {
		DeviceDBusProxy dp = null;
		foreach (var entry in this.devices.entries) {
			if (entry.value.device == dev) {
				dp = entry.value;
				break;
			}
		}
		return dp;
	}

	private void add_device_capability(Device dev,
									   string capability,
									   PacketHandlerInterface iface) {
		DeviceDBusProxy dp = find_proxy_for_device(dev);

		if (dp == null) {
			warning("no bus proxy for device %s", dev.to_string());
			return;
		}

		if (dp.has_handler(capability)) {
			return;
		}

		info("add capability handler %s for device at path %s",
				capability, dp.object_path.to_string());

		var h = PacketHandlersProxy.new_device_capability_handler(dev,
																  capability,
																  iface);
		if (h != null) {
			h.bus_register(this.bus, dp.object_path);
		}
	}

	/**
	 * make_device_path:
	 *
	 * return device path string that can be used as ObjectPath
	 */
	private string make_device_path() {
		var path =  "/org/mconnect/device/%d".printf(this.device_idx);

		// bump device index
		this.device_idx++;

		return path;
	}
}