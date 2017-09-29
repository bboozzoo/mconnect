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

using Mconn;

/**
 * Device communication channel
 *
 * Automatically handle channel encoding.
 */
class DeviceChannel : Object {

	public signal void disconnected();
	public signal void packet_received(Packet pkt);

	private InetSocketAddress _isa = null;
	private SocketConnection _sock_conn = null;
	private TlsConnection _tls_conn = null;
	private DataOutputStream _dout = null;
	private DataInputStream _din = null;
	private uint _srcid = 0;
	private Socket _socket = null;

	public TlsCertificate peer_certificate = null;

	public DeviceChannel(InetAddress host, uint port) {
		this._isa = new InetSocketAddress(host, (uint16) port);
	}

	~DeviceChannel() {
		debug("channel destroyed");
	}

	private static void fixup_socket(Socket sock) {
		Utils.socket_set_keepalive(sock);
	}

	private void replace_streams(InputStream input, OutputStream output) {
		if (this._dout != null) {
			try {
				this._dout.close();
			} catch (Error e) {
				warning("failed to close output stream: %s", e.message);
			}
		}
		this._dout = new DataOutputStream(output);

		if (this._din != null) {
			try {
				this._din.close();
			} catch (Error e) {
				warning("failed to close input stream: %s", e.message);
			}
		}
		this._din = new DataInputStream(input);
		// messages end with \n\n
		this._din.set_newline_type(DataStreamNewlineType.LF);
	}

	private void monitor_events() {
		var source = _socket.create_source(IOCondition.IN);
		source.set_callback((src, cond) => {
				return this._io_ready(cond);
			});
		// attach source
		this._srcid = source.attach(null);
	}

	private void unmonitor_events() {
		if (this._srcid > 0) {
			Source.remove(_srcid);
			this._srcid = 0;
		}
	}

	public async bool open() {
		GLib.assert(this._isa != null);

		debug("connect to %s:%u", this._isa.address.to_string(), this._isa.port);

		var client = new SocketClient();
		SocketConnection conn;
		try {
			conn = yield client.connect_async(_isa);
		} catch (Error e) {
			//
			warning("failed to connect to %s:%u: %s",
					 this._isa.address.to_string(), this._isa.port,
					 e.message);
			// emit disconnected
			return false;
		}

		debug("connected to %s:%u", this._isa.address.to_string(), this._isa.port);

		this._socket = conn.get_socket();

		// fixup socket keepalive
		fixup_socket(_socket);

		this._sock_conn = conn;

		// input/output streams will close underlying base stream when .close()
		// is called on them, make sure that we pass Unix*Stream with which can
		// skip closing the socket
		this.replace_streams(new UnixInputStream(_socket.fd, false),
						new UnixOutputStream(_socket.fd, false));

		// start monitoring socket events
		this.monitor_events();

		return true;
	}

	/**
	 * secure:
	 * Switch channel to TLS mode
	 *
	 * When TLS was established, `peer_certificate` will store the remote client
	 * certificate. If `expected_peer` is null, the peer certificate will be
	 * accepted unconditionally during handshake and the caller must eventually
	 * decide if the client is to be trusted or not. However, if `expected_peer`
	 * was set, the received certificate and expected one will be compared
	 * during handshake and connection will be rejected if a mismatch is found.
	 *
	 * @param expected_peer the peer certificate we are expecting to see
	 * @return true if TLS negotiation was successful, false otherwise
	 */
	public async bool secure(TlsCertificate? expected_peer = null) {
		GLib.assert(this._sock_conn != null);

		// stop monitoring socket events
		this.unmonitor_events();

		var cert = Core.instance().certificate;

		// wrap with TLS
		var tls_conn = Utils.make_tls_connection(this._sock_conn,
												 cert,
												 expected_peer);
		try {
			info("attempt TLS handshake");
			var res = yield tls_conn.handshake_async();
			if (res) {
				info("TLS handshare successful");
				this.peer_certificate = tls_conn.peer_certificate;
			} else {
				warning("TLS handshake unsuccessful");
				return false;
			}
		} catch (Error e) {
			warning("TLS handshake failed: %s", e.message);
			return false;
		}

		this._tls_conn = tls_conn;
		// data will now pass through TLS stream wrapper
		this.replace_streams(_tls_conn.input_stream,
							 _tls_conn.output_stream);

		// monitor socket events
		this.monitor_events();
		return true;
	}

	public void close() {
		debug("closing connection");

		this.unmonitor_events();

		try {
			if (this._din != null)
				this._din.close();
		} catch (Error e) {
			warning("failed to close data input: %s", e.message);
		}
		try {
			if (this._dout != null)
				this._dout.close();
		} catch (Error e) {
			warning("failed to close data output: %s", e.message);
		}
		try {
			if (this._tls_conn != null)
				this._tls_conn.close();
		} catch (Error e) {
			warning("failed to close TLS connection: %s", e.message);
		}
		try {
			if (this._sock_conn != null)
				this._sock_conn.close();
		} catch (Error e) {
			warning("failed to close connection: %s", e.message);
		}
		this._din = null;
		this._dout = null;
		this._sock_conn = null;
		this._tls_conn = null;
		this._socket = null;

		this.peer_certificate = null;
	}

	/**
	 * send:
	 * Possibly blocking
	 *
	 * @param: instance of Packet
	 **/
	public async void send(Packet pkt) {
		string to_send = pkt.to_string() + "\n";
		debug("send data: %s", to_send);

		GLib.assert(this._dout != null);

		try {
			this._dout.put_string(to_send);
		} catch (IOError e) {
			warning("failed to send message: %s", e.message);
			// TODO disconnect?
		}
	}

	/**
	 * receive:
	 * Try to receive some data from channel
	 *
	 * @return false if channel was closed, true otherwise
	 */
	public bool receive() {
		size_t line_len;
		string data = null;

		GLib.assert(this._din != null);

		try {
			// read line up to a newline
			data = this._din.read_upto("\n", -1, out line_len, null);

			// expecting \n
			this._din.read_byte();
		} catch (IOError ie) {
			warning("I/O error: %s", ie.message);
		}

		if (data == null) {
			debug("connection closed?");
			return false;
		}

		vdebug("received line: %s", data);

		Packet pkt = Packet.new_from_data(data);
		if (pkt == null) {
			warning("failed to build packet from data");
			// data was received, hence connection is still alive
			return true;
		}

		this.handle_packet(pkt);

		return true;
	}

	private bool _io_ready(uint flags) {
		debug("check for IO, conditions: 0x%x", flags);
		bool res = this.receive();

		if (res == false) {
			// disconnected
			this.disconnected();
		}
		return res;
	}

	private void handle_packet(Packet pkt) {
		// debug("handle packet of type: %s", pkt.pkt_type);
		if (pkt.pkt_type == Packet.ENCRYPTED) {
			warning("received packet with eplicit encryption, this usually indicates a protocol version < 6 type packet, such pacckets are no longer supported, dropping..");
		} else {
			// signal that we got a packet
			this.packet_received(pkt);
		}
	}
}