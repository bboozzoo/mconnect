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

class TelephonyHandler : Object, PacketHandlerInterface {

	private const string TELEPHONY = "kdeconnect.telephony";

	public string get_pkt_type() {
		return TELEPHONY;
	}

	private TelephonyHandler() {

	}

	public static TelephonyHandler instance() {
		return new TelephonyHandler();
	}

	public void use_device(Device dev) {
		dev.message.connect(this.message);
	}

	public void release_device(Device dev) {
		dev.message.disconnect(this.message);
	}

	public void message(Device dev, Packet pkt) {
		if (pkt.pkt_type != TELEPHONY) {
			return;
		}

		debug("got telephony packet");

		if (pkt.body.has_member("phoneNumber") == false ||
			pkt.body.has_member("event") == false)
			return;

		string number = pkt.body.get_string_member("phoneNumber");
		string ev = pkt.body.get_string_member("event");

		// string ticker = convert_to_utf8(raw_ticker);
		GLib.message("call from %s, status %s", number, ev);

		// handle only missed call and ringing events
		const string[] accepted_events = {"ringing", "missedCall"};

		if (ev in accepted_events) {
			string summary = "Other event";

			if (ev == "ringing")
				summary = "Incoming call";
			if (ev == "missedCall")
				summary = "Missed call";

			// check if ringing was cancelled
			if (ev == "missedCall" && pkt.body.has_member("isCancel")) {
				bool cancelled = pkt.body.get_boolean_member("isCancel");
				if (cancelled == true) {
					debug("call cancelled");
					return;
				}
			}

			// telephony packets have no time information
			var time = new DateTime.now_local();
			number = "%s %s".printf(time.format("%X"), number);

			var notif = new Notify.Notification(summary, number,
												"phone");
			try {
				notif.show();
			} catch (Error e) {
				critical("failed to show notification: %s", e.message);
			}

		}
	}
}