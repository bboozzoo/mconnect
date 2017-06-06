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
	public signal void found_new_device(Device dev);
	public signal void device_capability_added(Device dev,
											   string capability,
											   PacketHandlerInterface handler);

	public const string DEVICES_CACHE_FILE = "devices";

	private HashMap<string, Device> devices;

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
		vdebug("cache file: %s", cache_file);

		// make sure that cache dir exists
		DirUtils.create_with_parents(Core.get_cache_dir(),
									 0700);

		return cache_file;
	}

	/**
	 * Load known devices from cache and attempt pairing.
	 */
	public void load_cache() {
		var cache_file = get_cache_file();

		debug("try loading devices from device cache %s", cache_file);

		var kf = new KeyFile();
		try {
			kf.load_from_file(cache_file, KeyFileFlags.NONE);

			string[] groups = kf.get_groups();

			foreach (string group in groups) {
				var dev = Device.new_from_cache(kf, group);
				if (dev != null) {
					debug("device %s from cache", dev.to_string());
					handle_new_device(dev);
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
		// debug("update devices cache");

		if (devices.size == 0)
			return;

		var kf = new KeyFile();

		foreach (var dev in devices.values) {
			dev.to_cache(kf, dev.device_name);
		}

		try {
			// debug("saving to cache");
			FileUtils.set_contents(get_cache_file(),
								   kf.to_data());
		} catch (FileError e) {
			warning("failed to save to cache file %s: %s",
					get_cache_file(), e.message);
		}
	}

	public void handle_discovered_device(DiscoveredDevice discovered_dev) {
		debug("found device: %s", discovered_dev.to_string());

		var new_dev = new Device.from_discovered_device(discovered_dev);

		handle_new_device(new_dev);
	}

	public void handle_new_device(Device new_dev) {
		var is_new = false;
		string unique = new_dev.to_unique_string();
		vdebug("device key: %s", unique);

		if (this.devices.has_key(unique) == false) {
			debug("adding new device with key: %s", unique);

			this.devices.@set(unique, new_dev);

			is_new = true;
		} else {
			debug("device %s already present", unique);
		}

		var dev = this.devices.@get(unique);
		// update device information
		dev.update_from_device(new_dev);

		debug("allowed? %s", dev.allowed.to_string());
		// check if device is whitelisted in configuration
		if (!dev.allowed && device_allowed_in_config(dev)) {
			dev.allowed = true;
		}

		// update devices cache
		update_cache();

		if (dev.allowed) {
			// device is allowed
			activate_device(dev);
		} else {
			warning("skipping device %s activation, device not allowed",
					dev.to_string());
		}

		// notify everyone that a new device appeared
		if (is_new) {
			found_new_device(dev);
		}
	}

	private void activate_device(Device dev) {
		info("activating device %s, active: %s", dev.to_string(),
			 dev.is_active.to_string());

		if (!dev.is_active) {
			dev.paired.connect(this.device_paired);
			dev.disconnected.connect(this.device_disconnected);

			dev.activate();
		}
	}

	/**
	 * device_allowed_in_config:
	 * @dev device
	 *
	 * Returns true if a matching device is enabled via configuration file.
	 */
	private bool device_allowed_in_config(Device dev) {
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

		update_cache();

		if (status == true) {
			// register message handlers
			this.enable_protocol_handlers(dev);
		} else {
			this.disable_protocol_handlers(dev);

			// we're no longer interested in paired singnal
			dev.paired.disconnect(this.device_paired);

			// we're not paired anymore, deactivate if needed
			dev.deactivate();
		}

	}

	private void enable_protocol_handlers(Device dev) {
		var core = Core.instance();
		core.handlers.use_device(dev, (cap, handler) => {
				device_capability_added(dev, cap, handler);
			});
	}

	private void disable_protocol_handlers(Device dev) {
		var core = Core.instance();
		core.handlers.release_device(dev);
	}

	private void device_disconnected(Device dev) {
		debug("device %s got disconnected", dev.to_string());

		this.disable_protocol_handlers(dev);

		dev.paired.disconnect(this.device_paired);
		dev.disconnected.disconnect(this.device_disconnected);
	}

	/**
	 * allow_device:
	 * @path: device object path
	 *
	 * Allow given device
	 */
	public void allow_device(Device dev) {
		dev.allowed = true;

		// update device cache
		update_cache();

		// maybe activate if needed
		activate_device(dev);
	}
}