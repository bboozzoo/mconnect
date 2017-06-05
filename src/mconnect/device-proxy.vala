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

/**
 * General device wrapper.
 */
[DBus (name = "org.mconnect.Device")]
class DeviceDBusProxy : Object {

	public string id {
		get { return device.device_id; }
		private set {}
		default = "";
	}
	public string name {
		get { return device.device_name; }
		private set {}
		default = "";
	}
	public string device_type {
		get { return device.device_type; }
		private set {}
		default = "";
	}
	public uint protocol_version {
		get { return device.protocol_version; }
		private set {}
		default = 5;
	}
	public string address { get; private set; default = ""; }

	public bool is_paired {
		get { return device.is_paired; }
		private set {}
		default = false;
	}
	public bool allowed {
		get { return device.allowed; }
		private set {}
		default = false;
	}
	public bool is_active {
		get { return device.is_active; }
		private set {}
		default = false;
	}

	public string[] incoming_capabilities {
		get { return device.incoming_capabilities; }
		private set {}
	}

	public string[] outgoing_capabilities {
		get { return device.outgoing_capabilities; }
		private set {}
	}

	[DBus (visible = false)]
	public Device device {get; private set; default = null; }

	public DeviceDBusProxy.for_device(Device device) {
		this.device = device;
		this.address = "%s:%u".printf(device.host.to_string(),
									  device.tcp_port);
		this.device.notify.connect(this.update_properties);
	}

	private void update_properties(ParamSpec param) {
		debug("param %s changed", param.name);
	}
}