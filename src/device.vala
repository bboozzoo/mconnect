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

	public signal void paired(bool pair);
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

	// set to true if pair request was sent
	private bool _pair_in_progress = false;

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
		var core = Core.instance();
		yield _channel.send(Packet.new_identity("test-laptop",
												"dadada",
												core.handlers.interfaces,
												core.handlers.interfaces));
		this.pair_if_needed();
	}

	/**
	 * pair: sent pair request
	 *
	 * Internally changes pair requests state tracking.
	 *
	 * @param expect_response se to true if expecting a response
	 */
	public async void pair(bool expect_response = true) {
		if (this.host != null) {
			debug("start pairing");

			var core = Core.instance();
			string pubkey = core.crypt.get_public_key_pem();
			debug("public key: %s", pubkey);

			if (expect_response == true)
				_pair_in_progress = true;
			yield _channel.send(Packet.new_pair(pubkey));
		}
	}

	public void pair_if_needed() {
		if (is_paired == false && _pair_in_progress == false)
			this.pair();
	}

	public void activate() {
		assert(_channel == null);

		var core = Core.instance();
		_channel = new DeviceChannel(this.host, this.tcp_port,
									 core.crypt);
		_channel.connected.connect((c) => {
				this.greet();
			});
		_channel.disconnected.connect((c) => {
				this.handle_disconnect();
			});
		_channel.packet_received.connect((c, pkt) => {
				this.packet_received(pkt);
			});
		_channel.open();
		debug("open finished");
	}

	public void deactivate() {
		if (_channel == null)
			_channel.close();
		_channel = null;
	}

	/**
	 * activate_from_device:
	 *
	 * Try to activate using a newly discovered device. If device is
	 * already active, compare the host address to see if it
	 * changed. If so, close the current connection and activate with
	 * new address.
	 *
	 * @param dev device
	 */
	public void activate_from_device(Device dev) {
		if (host == null) {
			activate();
		} else if (dev.host.to_string() != host.to_string()) {
			// same host, assuming no activation needed
			deactivate();
			activate();
		} else {
			debug("device %s already active", dev.to_string());
		}
	}

	private void packet_received(Packet pkt) {
		debug("got packet");
		if (pkt.pkt_type == Packet.PAIR) {
			// pairing
			handle_pair_packet(pkt);
		} else {
			debug("signal packet");
			// emit signal
			message(pkt);
		}
	}

	private void handle_pair_packet(Packet pkt) {
		assert(pkt.pkt_type == Packet.PAIR);

		bool pair = pkt.body.get_boolean_member("pair");
		if (_pair_in_progress == true) {
			// response to host initiated pairing
			if (pair == true) {
				debug("device is paired, pairing complete");
				this.is_paired = true;
			} else {
				critical("pairing rejected by device");
				this.is_paired = false;
			}
			// pair completed
			_pair_in_progress = false;
		} else {
			debug("unsolicited pair change from device");
			if (pair == false) {
				// unpair from device
				this.is_paired = false;
			} else {
				// pair request from device
				this.pair(false);
			}
		}

		// emit signal
		paired(is_paired);
	}

	private void handle_disconnect() {
		// channel got disconnected
		debug("channel disconnected");
	}
}