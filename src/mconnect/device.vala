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
	public bool allowed {get; set; default = false; }
	public bool is_active {
		get { return (_channel != null); }
		set {}
		default = false;
	}

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
	public Device.from_discovered_device(DiscoveredDevice disc) {
		this.host = disc.host;
		this.device_name = disc.device_name;
		this.device_id = disc.device_id;
		this.device_type = disc.device_type;
		this.protocol_version = disc.protocol_version;
		this.tcp_port = disc.tcp_port;

		debug("new device: %s", this.to_string());
	}

	/**
	 * Constructs a new Device wrapper based on data read from device
	 * cache file.
	 *
	 * @cache: device cache file
	 * @name: device name
	 */
	public static Device? new_from_cache(KeyFile cache, string name) {
		debug("device from cache group %s", name);

		try {
			var dev = new Device();
			dev.device_id = cache.get_string(name, "deviceId");
			dev.device_name = cache.get_string(name, "deviceName");
			dev.device_type = cache.get_string(name, "deviceType");
			dev.protocol_version = cache.get_integer(name, "protocolVersion");
			dev.tcp_port = (uint) cache.get_integer(name, "tcpPort");
			var last_ip_str = cache.get_string(name, "lastIPAddress");
			debug("last known address: %s:%u", last_ip_str, dev.tcp_port);
			dev.allowed = cache.get_boolean(name, "allowed");

			var host = new InetAddress.from_string(last_ip_str);
			if (host == null) {
				debug("failed to parse last known IP address (%s) for device %s",
					  last_ip_str, name);
				return null;
			}
			dev.host = host;
			return dev;
		}
		catch (KeyFileError e) {
			warning("failed to load device data from cache: %s", e.message);
			return null;
		}
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

	/**
	 * Dump device information to cache
	 *
	 * @cache: device cache
	 * @name: group name
	 */
	public void to_cache(KeyFile cache, string name) {
		cache.set_string(name, "deviceId", this.device_id);
		cache.set_string(name, "deviceName", this.device_name);
		cache.set_string(name, "deviceType", this.device_type);
		cache.set_integer(name, "protocolVersion", (int) this.protocol_version);
		cache.set_integer(name, "tcpPort", (int) this.tcp_port);
		cache.set_string(name, "lastIPAddress", this.host.to_string());
		cache.set_boolean(name, "allowed", this.allowed);
	}

	private async void greet() {
		var core = Core.instance();
		string host_name = Environment.get_host_name();
		string user = Environment.get_user_name();
		yield _channel.send(Packet.new_identity(@"$user@$host_name",
												Environment.get_host_name(),
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
			this.pair.begin();
	}

	/**
	 * activate:
	 *
	 * Activate device. Triggers sending of #paired signal after
	 * successfuly opening a connection.
	 */
	public void activate() {
		assert(_channel == null);

		var core = Core.instance();
		_channel = new DeviceChannel(this.host, this.tcp_port,
									 core.crypt);
		_channel.disconnected.connect((c) => {
				this.handle_disconnect();
			});
		_channel.packet_received.connect((c, pkt) => {
				this.packet_received(pkt);
			});
		_channel.open.begin((c, res) => {
				this.channel_openend(_channel.open.end(res));
			});
	}

	/**
	 * deactivate:
	 *
	 * Deactivate device
	 */
	public void deactivate() {
		if (_channel != null) {
			close_and_cleanup();
		}
	}

	/**
	 * activate_from_device:
	 *
	 * Try to activate using information from device @dev. If device is
	 * already active, compare the host address to see if it
	 * changed. If so, close the current connection and activate with
	 * new address.
	 *
	 * @param dev device
	 */
	public void activate_from_device(Device dev) {
		if (host == null) {
			host = dev.host;
			tcp_port = dev.tcp_port;
			activate();
		} else if (dev.host.to_string() != host.to_string()) {
			deactivate();
			host = dev.host;
			tcp_port = dev.tcp_port;
			activate();
		} else {
			if (_channel == null) {
				activate();
			} else {
				// same host, assuming no activation needed
				debug("device %s already active", dev.to_string());
			}
		}
	}

    /**
	 * channel_openend:
	 *
	 * Callback after DeviceChannel.open() has completed. If the
	 * channel was successfuly opened, proceed with handshake.
	 */
	private void channel_openend(bool result) {
		debug("channel openend: %s", result.to_string());
		if (result == true) {
			greet.begin();
		} else {
			// failed to open channel, invoke cleanup
			channel_closed_cleanup();
		}
	}

	private void packet_received(Packet pkt) {
		debug("got packet");
		if (pkt.pkt_type == Packet.PAIR) {
			// pairing
			handle_pair_packet(pkt);
		} else {
			// we sent a pair request, but got another packet,
			// supposedly meaning we're alredy paired since the device
			// is sending us data
			if (_pair_in_progress == true) {
				_pair_in_progress = false;
				// just to be clear, send paired signal
				paired(true);
			}

			// emit signal
			message(pkt);
		}
	}

	/**
	 * handle_pair_packet:
	 *
	 * Handle incoming packet of Packet.PAIR type. Inside, try to
	 * guess if we got a response for a pair request, or is this an
	 * unsolicited pair request coming from mobile.
	 */
	private void handle_pair_packet(Packet pkt) {
		assert(pkt.pkt_type == Packet.PAIR);

		bool pair = pkt.body.get_boolean_member("pair");

		debug("pair in progress: %s is paired: %s pair: %s",
			  _pair_in_progress.to_string(), this.is_paired.to_string(),
			  pair.to_string());
		if (_pair_in_progress == true) {
			// response to host initiated pairing
			if (pair == true) {
				debug("device is paired, pairing complete");
				this.is_paired = true;
			} else {
				warning("pairing rejected by device");
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
				this.pair.begin(false);
			}
		}

		// emit signal
		paired(is_paired);
	}

	/**
	 * handle_disconnect:
	 *
	 * Handler for DeviceChannel.disconnected() signal
	 */
	private void handle_disconnect() {
		// channel got disconnected
		debug("channel disconnected");
		close_and_cleanup();
	}

	private void close_and_cleanup() {
		_channel.close();
		channel_closed_cleanup();
	}

	/**
	 * channel_closed_cleanup:
	 *
	 * Single cleanup point after channel has been closed
	 */
	private void channel_closed_cleanup() {
		debug("close cleanup");
		_channel = null;
		// emit disconnected
		disconnected();
	}
}