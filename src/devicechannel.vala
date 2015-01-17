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
 * Device communication channel
 *
 * Automatically handle channel encoding.
 */
class DeviceChannel : Object {

	public signal void connected();

	private InetSocketAddress _isa = null;
	private SocketConnection _conn = null;
	private DataOutputStream _dout = null;
	private DataInputStream _din = null;

	public signal void data_received(string data);

	public DeviceChannel(InetAddress host, uint port) {
		_isa = new InetSocketAddress(host, (uint16) port);
	}

	public async void open() {
		assert(this._isa != null);

		var client = new SocketClient();
		_conn = yield client.connect_async(_isa);

		debug("connected to %s:%u", _isa.address.to_string(), _isa.port);

		// use data streams
		_dout = new DataOutputStream(_conn.output_stream);
		_din = new DataInputStream(_conn.input_stream);
		// messages end with \n\n
		_din.set_newline_type(DataStreamNewlineType.LF);

		// setup socket monitoring
		var sock = _conn.get_socket();
		var source = sock.create_source(IOCondition.IN | IOCondition.ERR |
										IOCondition.HUP);
		source.set_callback((src, cond) => {
				this._io_ready();
				return true;
			});
		// attach source
		source.attach(null);

		connected();
	}

	public async void send(Packet pkt) {
		string to_send = pkt.to_string() + "\n";
		debug("send data: %s", to_send);
		// _dout.put_string(data);
		yield _conn.output_stream.write_async(to_send.data);
	}

	public async void receive(out Packet pkt) throws Error {
		size_t line_len;
		// read line up to newline
		string data = yield _din.read_upto_async("\n", -1,
												 Priority.DEFAULT,
												 null,
												 out line_len);
		debug("received line: %s", data);
		// expecting \n\n
		_din.read_byte();
		_din.read_byte();

		pkt = Packet.new_from_data(data);
	}

	private async void _io_ready() {
		debug("check for IO");
		try {
			debug("try read");
			Packet pkt;
			yield this.receive(out pkt);

		} catch (Error e) {
			critical("error occurred: %d: %s", e.code, e.message);
		}
	}
}