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

[DBus (name = "org.mconnect.Device.FindMyPhone")]
class FindMyPhoneHandlerProxy : Object, PacketHandlerInterfaceProxy {

    private Device device = null;
    private FindMyPhoneHandler find_my_phone_handler = null;

    public FindMyPhoneHandlerProxy.for_device_handler (Device dev,
                                                       PacketHandlerInterface iface) {
        this.device = dev;
        this.find_my_phone_handler = (FindMyPhoneHandler) iface;
    }

    [DBus (visible = false)]
    public void bus_register (DBusConnection conn, string path) throws IOError {
        conn.register_object (path, this);
    }

    [DBus (visible = false)]
    public void bus_unregister (DBusConnection conn) throws IOError {
        // conn.unregister_object(this);
    }

    public void ring () {
        this.find_my_phone_handler.ring (this.device);
    }
}