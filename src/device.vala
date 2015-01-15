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
class Device : Object {

	public signal void paired();
	public signal void connected();
	public signal void disconnected();
	public signal void message(Packet pkt);

	public string device_id { get; private set; default = ""; }
	public string device_name { get; private set; default = ""; }
	public string device_type { get; private set; default = ""; }
	public uint protocol_version {get; private set; default = 5; }
	public uint tcp_port {get; private set; default = 1714; }
	public InetAddress host { get; private set; default = null; }
	public bool is_paired { get; private set; default = false; }

	private DeviceChannel _channel = null;

	private Device() {

	}

	/**
	 * Constructs a new Device wrapper based on identity packet.
	 *
	 * @param pkt identity packet
	 * @param host source host that the packet came from
	 */
	public Device.from_identity(Packet pkt, InetAddress host) {

		debug("got packet: %s", pkt.to_string());

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

	/**
	 * Generates a unique string for this device
	 */
	public string to_unique_string() {
		return this.to_string().replace(" ", "-");
	}

	public string to_string() {
		return "%s-%s-%s-%u".printf(this.device_id, this.device_name,
									this.device_type, this.protocol_version);
	}

	private async void greet() {
		string[] interfaces = {"kdeconnect.notification",
							   "kdeconnect.battery",
							   "kdeconnect.ping"};
		yield _channel.send(Packet.new_identity("test-laptop",
												"dadada",
												interfaces, interfaces).to_string());
		this.pair_if_needed();
	}

	public async void pair() {
		if (this.host != null) {
			debug("start pairing");

			var core = Core.instance();
			string pubkey = core.crypt.get_public_key_pem();
			debug("public key: %s", pubkey);
			_channel.send(Packet.new_pair(pubkey).to_string());
		}
	}

	public void pair_if_needed() {
		if (this.is_paired == false)
			this.pair();
	}

	public void activate() {
		assert(_channel == null);

		_channel = new DeviceChannel(this.host, this.tcp_port);
		_channel.connected.connect((c) => {
				this.greet();
			});
		_channel.open();
		debug("open finished");
	}

	public void activate_from_device(Device dev) {

	}

}