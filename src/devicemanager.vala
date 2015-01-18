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
	private HashMap<string, Device> devices;

	public DeviceManager() {
		debug("device manager..");

		this.devices = new HashMap<string, Device>();
	}

	public void found_device(Device dev) {
		debug("found device: %s", dev.to_string());

		string unique = dev.to_unique_string();
		if (this.devices.has_key(unique) == false) {
			debug("adding new device with key: %s", unique);
			this.devices.@set(unique, dev);

			dev.paired.connect((d, p) => {
					device_paired(d, p);
				});
			dev.activate();
		} else {
			var known_dev = this.devices.@get(unique);
			known_dev.activate_from_device(dev);
		}
	}

	private void device_paired(Device dev, bool status) {
		if (status == true) {
			var core = Core.instance();
			// register message handlers
			core.handlers.use_device(dev);
		}
	}

}