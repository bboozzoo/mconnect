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

class Discovery : GLib.Object
{
	private Socket socket = null;

	public signal void device_found(DiscoveredDevice dev);

	public Discovery() {
	}

	~Discovery() {
		debug("cleaning up discovery...");
		if (this.socket != null) {
			this.socket.close();
		}
	}

	public void listen() throws Error {
		this.socket = new Socket(SocketFamily.IPV4,
								 SocketType.DATAGRAM,
								 SocketProtocol.UDP);
		var sa = new InetSocketAddress(new InetAddress.any(SocketFamily.IPV4),
									   1714);
		debug("start listening for new devices at: %s:%u",
			  sa.address.to_string(), sa.port);

		try {
			socket.bind(sa, false);
		} catch (Error e) {
			this.socket.close();
			this.socket = null;
			throw e;
		}

		var source = socket.create_source(IOCondition.IN);
		source.set_callback((s, c) => {
				this.incomingPacket();
				return true;
			});
		source.attach(MainContext.default());
	}

	private void incomingPacket() {
		vdebug("incoming packet");

		uint8 buffer[4096];
		SocketAddress sa;
		InetSocketAddress isa;

		try {
			ssize_t read = this.socket.receive_from(out sa, buffer);
			isa = (InetSocketAddress)sa;
			vdebug("got %zd bytes from: %s:%u", read,
				   isa.address.to_string(), isa.port);
		} catch (Error e) {
			warning("failed to receive packet: %s", e.message);
			return;
		}

		vdebug("message data: %s", (string)buffer);

		this.parsePacketFromHost((string) buffer, isa.address);
	}

	private void parsePacketFromHost(string data, InetAddress host) {
		// expecing an identity packet
		var pkt = Packet.new_from_data(data);
		if (pkt.pkt_type != Packet.IDENTITY) {
			message("unexpected packet type %s from device %s",
					pkt.pkt_type, host.to_string());
			return;
		}

		var dev = new DiscoveredDevice.from_identity(pkt, host);
		message("connection from device: \'%s\', responds at: %s:%u",
				dev.device_name, host.to_string(), dev.tcp_port);

		device_found(dev);
	}

	public void announce() {
		var sock = new Socket(SocketFamily.IPV4,
							  SocketType.DATAGRAM,
							  SocketProtocol.UDP);
		sock.broadcast = true;
		try {
			var sa = new InetSocketAddress(new InetAddress.from_string("255.255.255.255"),
										   1716);

			var core = Core.instance();

			var identity = Packet.new_identity(core.device_name,
											   core.device_id,
											   core.handlers.interfaces,
											   core.handlers.interfaces);

			debug("identity: %s", identity.to_string());
			sock.send_to(sa, identity.to_string().data);
		} catch (Error e) {
			warning("failed to send annoucement: %s", e.message);
		}
		sock.close();
	}
}
