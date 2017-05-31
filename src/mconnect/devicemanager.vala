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

class DeviceManager : GLib.Object
{
	public const string DEVICES_CACHE_FILE = "devices";

	private HashMap<string, Device> devices;

	public DeviceManager() {
		debug("device manager..");

		this.devices = new HashMap<string, Device>();

		// TODO: check for network connectivity first, possibly pass
		// this through the main loop
		load_cache();
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
	private void load_cache() {
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

	public void found_device(Device dev) {
		debug("found device: %s", dev.to_string());

		if (device_allowed(dev) == false) {
			message("device %s not on whitelist", dev.to_string());
			return;
		}

		string unique = dev.to_unique_string();
		debug("device key: %s", unique);
		if (this.devices.has_key(unique) == false) {
			debug("adding new device with key: %s", unique);
			this.devices.@set(unique, dev);

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

		// device in whitelist and added to currently used devices, so
		// it's ok to update the device cache
		update_cache();
	}

	private bool device_allowed(Device dev) {
		var core = Core.instance();
		return core.config.is_device_allowed(dev.device_name,
											 dev.device_type);

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

}