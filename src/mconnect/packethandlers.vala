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
using Gee;

class PacketHandlers : Object {

	private HashMap<string, PacketHandlerInterface> _handlers;

	public string[] interfaces {
		owned get { return _handlers.keys.to_array(); }
		private set {}
	}

	public PacketHandlers() {
		_handlers = load_handlers();
	}

	private static HashMap<string, PacketHandlerInterface> load_handlers() {
		HashMap<string, PacketHandlerInterface> hnd =
			new HashMap<string, PacketHandlerInterface>();

		var notification = NotificationHandler.instance();
		var battery = BatteryHandler.instance();
		var telephony = TelephonyHandler.instance();
		var mousepad = MousepadHandler.instance();
		var ping = PingHandler.instance();
		var share = ShareHandler.instance();

		hnd.@set(notification.get_pkt_type(), notification);
		hnd.@set(battery.get_pkt_type(), battery);
		hnd.@set(telephony.get_pkt_type(), telephony);
		hnd.@set(mousepad.get_pkt_type(), mousepad);
		hnd.@set(ping.get_pkt_type(), ping);
		hnd.@set(share.get_pkt_type(), share);

		return hnd;
	}

	/**
	 * SupportedCapabilityFunc:
	 * @capability: capability name
	 * @handler: packet handler
	 *
	 * User provided callback called when enabling @capability handled
	 * by @handler for a particular device.
	 */
	public delegate void SupportedCapabilityFunc(string capability,
												 PacketHandlerInterface handler);

	public PacketHandlerInterface? get_capability_handler(string cap) {
		// all handlers are singletones for now
		var h = this._handlers.@get(cap);
		return h;
	}

	public static string to_capability(string pkttype) {
		if (pkttype.has_suffix(".request"))
			return pkttype.replace(".request", "");
		return pkttype;
	}
}