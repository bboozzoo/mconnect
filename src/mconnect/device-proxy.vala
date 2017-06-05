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
		get;
		private set;
	}

	public string[] outgoing_capabilities {
		get;
		private set;
	}

	[DBus (visible = false)]
	public Device device {get; private set; default = null; }

	public DeviceDBusProxy.for_device(Device device) {
		this.device = device;
		this.update_address();
		this.update_capabilities();
		this.device.notify.connect(this.param_changed);
	}

	private void update_capabilities() {
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

	private void update_address() {
		this.address = "%s:%u".printf(device.host.to_string(),
									  device.tcp_port);
		this.device.notify.connect(this.update_properties);
	}

	private void update_properties(ParamSpec param) {
		debug("param %s changed", param.name);
	}

	private void param_changed(ParamSpec param) {
		debug("parameter %s changed", param.name);
		switch (param.name) {
		case "host":
		case "tcp-port":
			this.update_address();
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
			this.update_capabilities();
			break;
		}
	}
}