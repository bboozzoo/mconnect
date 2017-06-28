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
	private static string DOWNLOADS = null;

	public void use_device(Device dev) {
		debug("use device %s for sharing", dev.to_string());
		dev.message.connect(this.message);
	}

	private ShareHandler() {
	}

	public static ShareHandler instance() {
		if (ShareHandler.DOWNLOADS == null) {

			GLib.warning("tutaj");
			ShareHandler.DOWNLOADS = Path.build_filename(
				Environment.get_user_special_dir(UserDirectory.DOWNLOAD),
				"mconnect");

			if (DirUtils.create_with_parents(ShareHandler.DOWNLOADS,
											 0700) == -1) {
				warning("failed to create downloads directory: %s",
						Posix.strerror(Posix.errno));
			}
		}

		info("downloads will be saved to %s", ShareHandler.DOWNLOADS);
		return new ShareHandler();
	}

	private static string make_downloads_path(string name) {
		return Path.build_filename(ShareHandler.DOWNLOADS, name);
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

		if (pkt.payload == null) {
			warning("missing payload info");
			return;
		}

		string name = pkt.body.get_string_member("filename");
		debug("file: %s size: %s", name, format_size(pkt.payload.size));

		var t = new DownloadTransfer(
			new InetSocketAddress(dev.host,
								  (uint16) pkt.payload.port),
			pkt.payload.size,
			make_downloads_path(name));

		t.start();
	}
}