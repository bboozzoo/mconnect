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

	private const string SHARE = "kdeconnect.share.request";
	private const string SHARE_PKT = "kdeconnect.share";

	public void use_device(Device dev) {
		debug("use device %s for sharing", dev.to_string());
		dev.message.connect(this.message);
	}

	private ShareHandler() {
	}

	public static ShareHandler instance() {
		return new ShareHandler();
	}

	public string get_pkt_type() {
		return SHARE;
	}

	public void release_device(Device dev) {
		debug("release device %s", dev.to_string());
		dev.message.disconnect(this.message);
	}

	private void message(Device dev, Packet pkt) {
		if (pkt.pkt_type != SHARE_PKT) {
			return;
		}

		warning("share packet");

		if (pkt.payload == null) {
			warning("missing payload info");
			return;
		}

		string name = pkt.body.get_string_member("filename");
		debug("file: %s size: %lld", name, pkt.payload.size);
	}
}