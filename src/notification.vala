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

class NotificationHandler : Object, PacketHandlerInterface {

	private const string  NOTIFICATION = "kdeconnect.notification";

	public string get_pkt_type() {
		return NOTIFICATION;
	}

	private NotificationHandler() {

	}

	public static NotificationHandler instance() {
		return new NotificationHandler();
	}

	public void use_device(Device dev) {
		dev.message.connect((d, pkt) => {
				if (pkt.pkt_type == NOTIFICATION) {
					this.message(pkt);
				}
			});
	}

	public void message(Packet pkt) {
		debug("got notification packet");

		// get application ID
		string id = pkt.body.get_string_member("id");

		// dialer notifications are handled by telephony plugin
		if (id.match_string("com.android.dialer", false) == true)
			return;

		// other notifications
		if (pkt.body.has_member("appName") == false ||
			pkt.body.has_member("ticker") == false)
			return;

		string app = pkt.body.get_string_member("appName");
		string ticker = pkt.body.get_string_member("ticker");

		// skip empty notifications
		if (ticker.length == 0)
			return;

		GLib.message("notification from %s: %s", app, ticker);

		var notif = new Notify.Notification(app, ticker,
											"dialog-information");
		notif.show();
	}
}