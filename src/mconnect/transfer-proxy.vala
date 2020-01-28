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

[DBus (name = "org.mconnect.Transfer")]
class TransferDBusProxy : Object {

    [DBus (visible = false)]
    public TransferInterface transfer {
        get; private set; default = null;
    }

    private ObjectPath object_path = null;
    private uint register_id = 0;

    public TransferDBusProxy.for_transfer_with_path (TransferInterface transfer,
                                                     ObjectPath path) {
        this.transfer = transfer;
        this.object_path = path;
    }

    [DBus (visible = false)]
    public void bus_register (DBusConnection conn) throws Error {
        debug ("register transfer at path %s", this.object_path.to_string ());
        this.register_id = conn.register_object (this.object_path, this);
    }

    [DBus (visible = false)]
    public void bus_unregister (DBusConnection conn) throws Error {
        if (this.register_id != 0) {
            debug ("unregister transfer at path %s", this.object_path.to_string ());
            conn.unregister_object (this.register_id);
        }
    }

    public void cancel () throws Error {
        debug ("cancelling job");
        this.transfer.cancel ();
    }
}
