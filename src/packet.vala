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

	public const int PROTOCOL_VERSION = 5;

	public const string IDENTITY = "kdeconnect.identity";
	public const string PAIR = "kdeconnect.pair";
	public const string ENCRYPTED = "kdeconnect.encrypted";

	public string pkt_type { get; private set; default = ""; }
	public int64 id { get; private set; default = 0; }
	public Json.Object body { get; private set; default = null; }

	public Packet(string type, Json.Object body, int64 id = 0) {
		this.pkt_type = type;
		this.body = body;
		if (id == 0) {
			this.id = get_real_time() / 1000;
		} else {
			this.id = id;
		}
	}

	public static Packet? new_from_data(string data) {
		var jp = new Json.Parser();

		try {
			jp.load_from_data(data, -1);
			var root_obj = jp.get_root().get_object();
			var type = root_obj.get_string_member("type");
			var id = root_obj.get_int_member("id");
			var body = root_obj.get_object_member("body");

			debug("packet type: %s", type);

			return new Packet(type, body, id);
		} catch (Error e) {
			message("failed to parse message: \'%s\', error: %s",
					data, e.message);
		}
		return null;
	}

	public static Packet new_pair(string key, bool pair = true) {
		var builder = new Json.Builder();
		builder.begin_object();
		builder.set_member_name("pair");
		builder.add_boolean_value(pair);
		builder.set_member_name("publicKey");
		builder.add_string_value(key);
		builder.end_object();

		var data_obj = builder.get_root().get_object();

		return new Packet(PAIR, data_obj);
	}

	public static Packet new_identity(string name,
									  string device_id,
									  string[] in_interfaces,
									  string[] out_interfaces,
									  string device_type = "desktop") {
		var builder = new Json.Builder();
		builder.begin_object();
		builder.set_member_name("deviceName");
		builder.add_string_value(name);
		builder.set_member_name("deviceId");
		builder.add_string_value(device_id);
		builder.set_member_name("deviceType");
		builder.add_string_value(device_type);
		builder.set_member_name("SupportedIncomingInterfaces");
		builder.add_string_value(string.joinv(",", in_interfaces));
		builder.set_member_name("SupportedOutgoingInterfaces");
		builder.add_string_value(string.joinv(",", out_interfaces));
		builder.set_member_name("protocolVersion");
		builder.add_int_value(PROTOCOL_VERSION);
		builder.end_object();

		var data_obj = builder.get_root().get_object();

		return new Packet(IDENTITY, data_obj);
	}

	public string to_string() {
		var gen = new Json.Generator();
		// root node
		var root = new Json.Node(Json.NodeType.OBJECT);
		var root_obj = new Json.Object();
		root_obj.set_string_member("type", pkt_type);
		root_obj.set_int_member("id", id);
		root_obj.set_object_member("body", body);
		root.set_object(root_obj);

		gen.set_root(root);
		gen.set_pretty(false);

		var data = gen.to_data(null);

		return data;
	}
}