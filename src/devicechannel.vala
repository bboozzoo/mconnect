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
		// _dout = new DataOutputStream(_conn.output_stream);
		// _din = new DataInputStream(_conn.input_stream);

		debug("connected to %s:%u", _isa.address.to_string(), _isa.port);

		connected();
	}

	public async void send(string message) {
		string to_send = message + "\n";
		debug("send data: %s", to_send);
		// _dout.put_string(data);
		yield _conn.output_stream.write_async(to_send.data);
	}

	public async void receive(out string data) throws Error {
		var received = yield _conn.input_stream.read_bytes_async(4096);
		debug("received data: %zu", received.get_size());
	}
}