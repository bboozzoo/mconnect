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
class DeviceManager : GLib.Object
{
	public const string DEVICES_CACHE_FILE = "devices";

	private HashMap<string, DeviceWrapper?> devices;
	private int device_idx = 0;

	/**
	 * DBus wrapper for devices
	 */
	private struct DeviceWrapper {
        ObjectPath object_path;
        Device device;

        DeviceWrapper (string path, Device device) {
            this.object_path = new ObjectPath(path);
            this.device = device;
        }
    }


	public DeviceManager() {
		debug("device manager..");

		this.devices = new HashMap<string, DeviceWrapper?>();
	}

	/**
	 * Obtain path to devices cache file
	 */
	private string get_cache_file() {
		var cache_file = Path.build_filename(Core.get_cache_dir(),
											 DEVICES_CACHE_FILE);
		debug("cache file: %s", cache_file);

		// make sure that cache dir exists
		DirUtils.create_with_parents(Core.get_cache_dir(),
									 0700);

		return cache_file;
	}

	/**
	 * Load known devices from cache and attempt pairing.
	 */
	[DBus (visible = false)]
	public void load_cache() {
		debug("try loading devices from device cache");

		var cache_file = get_cache_file();

		var kf = new KeyFile();
		try {
			kf.load_from_file(cache_file, KeyFileFlags.NONE);

			string[] groups = kf.get_groups();

			foreach (string group in groups) {
				var dev = Device.new_from_cache(kf, group);
				if (dev != null) {
					debug("device %s from cache", dev.to_string());
					found_device(dev);
				}
			}
		} catch (Error e) {
			debug("error loading cache file: %s", e.message);
		}
	}

	/**
	 * Update contents of device cache
	 */
	private void update_cache() {
		debug("update devices cache");

		if (devices.size == 0)
			return;

		var kf = new KeyFile();

		foreach (var wrapper in devices.values) {
			var dev = wrapper.device;
			dev.to_cache(kf, dev.device_name);
		}

		try {
			debug("saving to cache");
			FileUtils.set_contents(get_cache_file(),
								   kf.to_data());
		} catch (FileError e) {
			debug("failed to save to cache file %s: %s",
				  get_cache_file(), e.message);
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
		device_idx++;

		return path;
	}

	[DBus (visible = false)]
	public void found_device(Device dev) {
		debug("found device: %s", dev.to_string());

		var is_new = false;
		string unique = dev.to_unique_string();
		debug("device key: %s", unique);

		if (this.devices.has_key(unique) == false) {
			debug("adding new device with key: %s", unique);
			this.devices.@set(unique,
							  DeviceWrapper(make_device_path(), dev));
			is_new = true;
		} else {
			var wrapper = this.devices.@get(unique);
			dev = wrapper.device;
		}

		if (device_allowed(dev)) {
			dev.allowed = true;
		}

		// update devices cache
		update_cache();

		if (dev.allowed) {
			// device is allowed
			activate_device(dev);
		} else {
			message("skipping device %s activation, device not allowed", dev.to_string());
		}
	}

	private void activate_device(Device dev) {
		info("activating device %s", dev.to_string());

		dev.paired.connect((d, p) => {
				device_paired(d, p);
			});

		dev.disconnected.connect((d) => {
				device_disconnected(d);
			});

		dev.activate_from_device(dev);
	}

	private bool device_allowed(Device dev) {
		if (dev.allowed)
			return true;

		var core = Core.instance();

		var in_config = core.config.is_device_allowed(dev.device_name,
													  dev.device_type);
		return in_config;
	}

	private void device_paired(Device dev, bool status) {
		info("device %s pair status change: %s",
			 dev.to_string(), status.to_string());

		if (status == true) {
			var core = Core.instance();
			// register message handlers
			core.handlers.use_device(dev);
		} else {
			// we're not paired anymore, deactivate if needed
			dev.deactivate();
		}

	}

	private void device_disconnected(Device dev) {
		debug("device %s got disconnected", dev.to_string());
	}

	/**
	 * allow_device:
	 * @path: device object path
	 *
	 * Allow given device
	 */
	public void allow_device(string path) {
		debug("allow device %s", path);

		Device dev = null;
		foreach (var dw in this.devices.values) {
			if (dw.object_path == path)
				dev = dw.device;
		}

		if (dev == null) {
			warning("device with path %s not found", path);
			return;
		}

		dev.allowed = true;

		// update device cache
		update_cache();

		// maybe activate if needed
		activate_device(dev);
	}

	/**
	 * list_devices:
	 *
	 * Returns a list of DBus paths of all known devices
	 */
	public ObjectPath[] list_devices() {
		ObjectPath[] devices = {};

		foreach (var dw in this.devices.values) {
			devices += dw.object_path;
		}
		return devices;
	}
}