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

	private HashMap<string, Device> devices;

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

		this.devices = new HashMap<string, Device>();
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

		foreach (Device dev in devices.values) {
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

	[DBus (visible = false)]
	public void found_device(Device dev) {
		debug("found device: %s", dev.to_string());

		if (device_allowed(dev) == false) {
			message("device %s not on whitelist", dev.to_string());
		}

		var is_new = false;
		string unique = dev.to_unique_string();
		debug("device key: %s", unique);

		if (this.devices.has_key(unique) == false) {
			debug("adding new device with key: %s", unique);
			this.devices.@set(unique, dev);
			is_new = true;
		}

		// update devices cache
		update_cache();

		if (dev.allowed) {
			// device is allowed

			if (is_new) {
				dev.paired.connect((d, p) => {
						device_paired(d, p);
					});

				dev.disconnected.connect((d) => {
						device_disconnected(d);
					});
				dev.activate();
			} else {
				debug("activate from device");
				var known_dev = this.devices.@get(unique);
				known_dev.activate_from_device(dev);
			}
		}
	}

	private bool device_allowed(Device dev) {
		if (dev.allowed)
			return true;

		var core = Core.instance();

		var in_config = core.config.is_device_allowed(dev.device_name,
													  dev.device_type);
		dev.allowed = in_config;
		return in_config;
	}

	private void device_paired(Device dev, bool status) {
		if (status == true) {
			var core = Core.instance();
			// register message handlers
			core.handlers.use_device(dev);
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

	}

	/**
	 * list_devices:
	 *
	 * Returns a list of DBus paths of all known devices
	 */
	public ObjectPath[] list_devices() {
		ObjectPath[] devices = {};
		return devices;
	}

}