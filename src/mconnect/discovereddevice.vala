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
 * Newly discovered device wrapper.
 */
class DiscoveredDevice : Object {

	public string device_id { get; private set; default = ""; }
	public string device_name { get; private set; default = ""; }
	public string device_type { get; private set; default = ""; }
	public uint protocol_version {get; private set; default = 5; }
	public uint tcp_port {get; private set; default = 1714; }
	public InetAddress host { get; private set; default = null; }
	public string[] outgoing_capabilities { get; private set; default = null; }
	public string[] incoming_capabilities { get; private set; default = null; }

	/**
	 * Constructs DiscoveredDevice based on identity packet.
	 *
	 * @param pkt identity packet
	 * @param host source host that the packet came from
	 */
	public DiscoveredDevice.from_identity(Packet pkt, InetAddress host) {

		debug("got packet: %s", pkt.to_string());

		var body = pkt.body;
		this.host = host;
		this.device_name = body.get_string_member("deviceName");
		this.device_id = body.get_string_member("deviceId");
		this.device_type = body.get_string_member("deviceType");
		this.protocol_version = (int) body.get_int_member("protocolVersion");
		this.tcp_port = (uint) body.get_int_member("tcpPort");

		var incoming = body.get_array_member("incomingCapabilities");
		var outgoing = body.get_array_member("outgoingCapabilities");
		this.outgoing_capabilities = new string[outgoing.get_length()];
		this.incoming_capabilities = new string[incoming.get_length()];

		incoming.foreach_element((a, i, n) => {
				this.incoming_capabilities[i] = n.get_string();
			});
		outgoing.foreach_element((a, i, n) => {
				this.outgoing_capabilities[i] = n.get_string();
			});

		debug("discovered new device: %s", this.to_string());
	}

	public string to_string() {
		return "discovered-%s-%s-%s-%u".printf(this.device_id,
											   this.device_name,
											   this.device_type,
											   this.protocol_version);
	}

	public string to_unique_string() {
		return Utils.make_unique_device_string(this.device_id,
											   this.device_name,
											   this.device_type,
											   this.protocol_version);
	}

}