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

[DBus (name = "org.mconnect.Device.Share")]
class ShareHandlerProxy : Object, PacketHandlerInterfaceProxy {

	private Device device = null;
	private ShareHandler share_handler = null;

	public ShareHandlerProxy.for_device_handler(Device dev,
												PacketHandlerInterface iface) {
		this.device = dev;
		this.share_handler = (ShareHandler) iface;
	}

	[DBus (visible = false)]
	public void bus_register(DBusConnection conn, string path) throws IOError {
		conn.register_object(path, this);
	}

	[DBus (visible = false)]
	public void bus_unregister(DBusConnection conn) throws IOError {
		//conn.unregister_object(this);
	}

	public void share_file(string path) throws IOError {

	}

	public void share_url(string url) throws IOError {
		debug("share url %s", url);
		this.share_handler.share_url(this.device, url);
	}

	public void share_text(string text) throws IOError {
		this.share_handler.share_text(this.device, text);
	}
}