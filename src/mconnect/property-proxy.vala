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

/**
 * DBusPropertyNotifier:
 *
 * Helper class for pushing out
 * org.freedesktop.DBus.Properties.PropertiesChanged signals.
 */
class DBusPropertyNotifier : Object {

    private DBusConnection conn = null;
    private string iface = "";
    private string path = "";
    private VariantBuilder builder = null;
    private uint timeout_src = 0;

    public const uint TIMEOUT = 300;

    public DBusPropertyNotifier (DBusConnection conn,
                                 string iface,
                                 string path) {
        this.conn = conn;
        this.iface = iface;
        this.path = path;
    }

    /**
     * queue_property_change:
     *
     * @name: property name (will be automatically capitalized if needed)
     * @val: Variant holding property value
     *
     * This method will queue up property notifications for sending. By default
     * it waits @TIMEOUT ms before sending the actual signal.
     */
    public void queue_property_change (string name, Variant val) {
        if (this.builder == null) {
            this.builder = new VariantBuilder (VariantType.ARRAY);
        }

        string nm = name;
        if (name.get_char (0).islower ()) {
            nm = name.get_char (0).toupper ().to_string () + name.substring (1);
        }

        this.builder.add ("{sv}", nm, val);

        if (this.timeout_src == 0) {
            this.timeout_src = Timeout.add (300,
                                            this.send_property_change);
        }
    }

    /**
     * send_property_change:
     *
     * Send out actual PropertiesChanged signals
     */
    private bool send_property_change () {
        this.timeout_src = 0;

        if (this.builder == null)
            return false; ;

        try {
            var invalid_builder = new VariantBuilder (new VariantType ("as"));

            this.conn.emit_signal (null,
                                   this.path,
                                   "org.freedesktop.DBus.Properties",
                                   "PropertiesChanged",
                                   new Variant ("(sa{sv}as)",
                                                this.iface,
                                                builder,
                                                invalid_builder)
                                   );
        } catch (Error e) {
            warning ("%s\n", e.message);
        }

        this.builder = null;

        return false;
    }
}