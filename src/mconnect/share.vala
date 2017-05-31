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

class ShareHandler : Object, PacketHandlerInterface {

	private const string SHARE = "kdeconnect.share";

	public string get_pkt_type() {
		return SHARE;
	}

	private ShareHandler() {

	}

	public static ShareHandler instance() {
		return new ShareHandler();
	}

	public void use_device(Device dev) {
		dev.message.connect((d, pkt) => {
				debug("message signal");
				if (pkt.pkt_type == SHARE) {
					debug("share packet");
					this.message(pkt);
				}
			});
	}

	public void message(Packet pkt) {
		debug("got share packet");

		if (pkt.payload_size == 0 || pkt.payload_transfer == null) {
			warning("payload size %lld nor no transfer info?", pkt.payload_size);
			return;
		}

		string filename;
		if (pkt.body.has_member("filename")) {
			filename = pkt.body.get_string_member("filename");
		} else {
			// TODO generate filename
		}
	}
}