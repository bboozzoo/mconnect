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

class Device : Object {
	public string device_id { get; private set; default = ""; }
	public string device_name { get; private set; default = ""; }
	public string device_type { get; private set; default = ""; }
	public uint protocol_version {get; private set; default = 5; }
	public uint tcp_port {get; private set; default = 1714; }
	public InetAddress host { get; private set; }
	public bool paired { get; set; default = false; }

	public Device() {

	}

	public Device.from_identity(Packet pkt, InetAddress host) {
		var body = pkt.body;
		this.host = host;
		this.device_name = body.get_string_member("deviceName");
		this.device_id = body.get_string_member("deviceId");
		this.device_type = body.get_string_member("deviceType");
		this.protocol_version = (int) body.get_int_member("protocolVersion");
		this.tcp_port = (uint) body.get_int_member("tcpPort");

		debug("added new device: %s", this.to_string());
	}

	~Device() {

	}

	public string to_unique_string() {
		return "";
	}

	public string to_string() {
		return "%s-%s-%s-%u".printf(this.device_id, this.device_name,
									this.device_type, this.protocol_version);
	}

}