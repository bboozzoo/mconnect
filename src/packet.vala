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

using Json;

class Packet : GLib.Object {
	public const string IDENTITY = "kdeconnect.identity";
	public const string PAIR = "kdeconnect.pair";
	public const string ENCRYPT = "kdeconnect.encrypt";

	public string pkt_type { get; private set; default = ""; }
	public Json.Object body { get; private set; default = null; }

	private Packet(string type, Json.Object body) {
		this.pkt_type = type;
		this.body = body;
	}

	public static Packet? new_from_data(string data) {
		var jp = new Json.Parser();

		try {
			jp.load_from_data(data, -1);
			var root_obj = jp.get_root().get_object();
			var type = root_obj.get_string_member("type");
			debug("packet type: %s", type);
			var body = root_obj.get_object_member("body");
			// var device_name = body.get_string_member("deviceName");
			// var port = (uint) body.get_int_member("tcpPort");
			return new Packet(type, body);
		} catch (Error e) {
			message("failed to parse message: \'%s\', error: %s",
					data, e.message);
		}
		return null;
	}

	public string decrypt() {
		return "";
	}
}