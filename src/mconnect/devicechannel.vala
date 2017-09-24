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
using Posix;

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
		_isa = new InetSocketAddress(host, (uint16) port);
	}

	~DeviceChannel() {
		debug("channel destroyed");
	}

	private void fixup_socket(Socket sock) {
#if 0
		IPPROTO_TCP = 6,	   /* Transmission Control Protocol.  */

		TCP_KEEPIDLE	 4  /* Start keeplives after this period */
		TCP_KEEPINTVL	 5  /* Interval between keepalives */
		TCP_KEEPCNT		 6  /* Number of keepalives before death */
#endif
#if 0
		int option = 10;
		Posix.setsockopt(sock.fd, 6, 4, &option, (Posix.socklen_t) sizeof(int));
		option = 5;
		Posix.setsockopt(sock.fd, 6, 5, &option, (Posix.socklen_t) sizeof(int));
		option = 3;
		Posix.setsockopt(sock.fd, 6, 6, &option, (Posix.socklen_t) sizeof(int));
#endif
		int option = 10;
		Posix.setsockopt(sock.fd, IPProto.TCP,
						 Posix.TCP_KEEPIDLE,
						 &option, (Posix.socklen_t) sizeof(int));
		option = 5;
		Posix.setsockopt(sock.fd, IPProto.TCP,
						 Posix.TCP_KEEPINTVL,
						 &option, (Posix.socklen_t) sizeof(int));
		option = 3;
		Posix.setsockopt(sock.fd, IPProto.TCP,
						 Posix.TCP_KEEPCNT,
						 &option, (Posix.socklen_t) sizeof(int));

		// enable keepalive
		sock.set_keepalive(true);
	}

	private void replace_streams(InputStream input, OutputStream output) {
		if (_dout != null) {
			_dout.close();
		}
		_dout = new DataOutputStream(output);

		if (_din != null) {
			_din.close();
		}
		_din = new DataInputStream(input);
		// messages end with \n\n
		_din.set_newline_type(DataStreamNewlineType.LF);
	}

	private void monitor_events() {
		var source = _socket.create_source(IOCondition.IN);
		source.set_callback((src, cond) => {
				return this._io_ready(cond);
			});
		// attach source
		_srcid = source.attach(null);
	}

	private void unmonitor_events() {
		if (_srcid > 0) {
			Source.remove(_srcid);
			_srcid = 0;
		}
	}

	public async bool open() {
		GLib.assert(this._isa != null);

		debug("connect to %s:%u", _isa.address.to_string(), _isa.port);

		var client = new SocketClient();
		SocketConnection conn;
		try {
			conn = yield client.connect_async(_isa);
		} catch (Error e) {
			//
			warning("failed to connect to %s:%u: %s",
					 _isa.address.to_string(), _isa.port,
					 e.message);
			// emit disconnected
			return false;
		}

		debug("connected to %s:%u", _isa.address.to_string(), _isa.port);

		_socket = conn.get_socket();

		// fixup socket keepalive
		fixup_socket(_socket);

		_sock_conn = conn;

		// input/output streams will close underlying base stream when .close()
		// is called on them, make sure that we pass Unix*Stream with which can
		// skip closing the socket
		replace_streams(new UnixInputStream(_socket.fd, false),
						new UnixOutputStream(_socket.fd, false));

		// start monitoring socket events
		monitor_events();

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
		unmonitor_events();

		var cert = Core.get_certificate();

		// wrap with TLS
		var tls_conn = TlsServerConnection.@new(_sock_conn, cert);
		tls_conn.authentication_mode = TlsAuthenticationMode.REQUESTED;
		tls_conn.accept_certificate.connect((peer_cert, errors) => {
				info("accept certificate, flags: 0x%x", errors);
				info("certificate:\n%s\n", peer_cert.certificate_pem);

				this.peer_certificate = peer_cert;

				if (expected_peer != null) {
					if (DebugLog.Verbose) {
						vdebug("verify certificate, expecting: %s, got: %s",
							   expected_peer.certificate_pem,
							   peer_cert.certificate_pem);
					}

					if (expected_peer.is_same(peer_cert)) {
						return true;
					} else {
						warning("rejecting handshare, peer certificate mismatch, got:\n%s",
								peer_cert.certificate_pem);
						return false;
					}
				}
				return true;
			});

		try {
			info("attempt TLS handshake");
			var res = yield tls_conn.handshake_async();
			info("TLS handshare successful");
		} catch (Error e) {
			warning("TLS handshake failed: %s", e.message);
			return false;
		}

		_tls_conn = tls_conn;
		// data will now pass through TLS stream wrapper
		replace_streams(_tls_conn.input_stream,
						_tls_conn.output_stream);

		// monitor socket events
		monitor_events();
		return true;
	}

	public void close() {
		debug("closing connection");

		unmonitor_events();

		try {
			if (_din != null)
				_din.close();
		} catch (Error e) {
			warning("failed to close data input: %s", e.message);
		}
		try {
			if (_dout != null)
				_dout.close();
		} catch (Error e) {
			warning("failed to close data output: %s", e.message);
		}
		try {
			if (_tls_conn != null)
				_tls_conn.close();
		} catch (Error e) {
			warning("failed to close TLS connection: %s", e.message);
		}
		try {
			if (_sock_conn != null)
				_sock_conn.close();
		} catch (Error e) {
			warning("failed to close connection: %s", e.message);
		}
		_din = null;
		_dout = null;
		_sock_conn = null;
		_tls_conn = null;
		_socket = null;

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

		GLib.assert(_dout != null);

		try {
			_dout.put_string(to_send);
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

		GLib.assert(_din != null);

		try {
			// read line up to a newline
			data = _din.read_upto("\n", -1, out line_len, null);

			// expecting \n
			_din.read_byte();
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

		handle_packet(pkt);

		return true;
	}

	private bool _io_ready(uint flags) {
		debug("check for IO, conditions: 0x%x", flags);
		bool res = this.receive();

		if (res == false) {
			// disconnected
			disconnected();
		}
		return res;
	}

	private void handle_packet(Packet pkt) {
		// debug("handle packet of type: %s", pkt.pkt_type);
		if (pkt.pkt_type == Packet.ENCRYPTED) {
			warning("received packet with eplicit encryption, this usually indicates a protocol version < 6 type packet, such pacckets are no longer supported, dropping..");
		} else {
			// signal that we got a packet
			packet_received(pkt);
		}
	}
}