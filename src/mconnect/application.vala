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

namespace Mconn {

    public class Application : GLib.Application {

        private Core core = null;

        private static bool log_debug = false;
        private static bool log_debug_verbose = false;

        private const GLib.OptionEntry[] options = {
            { "debug", 'd', 0, OptionArg.NONE, ref log_debug,
              "Show debug output", null },
            { "verbose-debug", 0, 0, OptionArg.NONE, ref log_debug_verbose,
              "Show verbose debug output", null },
            { null }
        };

        private Discovery discovery = null;
        private DeviceManager manager = null;
        private DeviceManagerDBusProxy bus_manager = null;
        private TransferManager transfer = null;
        private TransferManagerDBusProxy bus_transfer = null;

        public Application () {
            Object (application_id: "org.mconnect");
            add_main_option_entries (options);

            discovery = new Discovery ();
            manager = new DeviceManager ();
            transfer = new TransferManager ();
        }

        protected override void startup () {
            debug ("startup");

            base.startup ();

            if (log_debug == true)
                Environment.set_variable ("G_MESSAGES_DEBUG", "all", false);

            if (log_debug_verbose == true)
                Logging.enable_vdebug ();

            core = Core.instance ();
            if (core == null)
                error ("cannot initialize core");

            core.transfer_manager = this.transfer;

            if (core.config.is_debug_on () == true)
                Environment.set_variable ("G_MESSAGES_DEBUG", "all", false);

            Notify.init ("mconnect");

            discovery.device_found.connect ((disc, discdev) => {
                manager.handle_discovered_device (discdev);
            });

            try {
                discovery.listen ();
            } catch (Error e) {
                message ("failed to setup device listener: %s", e.message);
            }
        }

        protected override void activate () {
            debug ("activate");
            // reload devices from cache
            manager.load_cache ();
            hold ();
        }

        public override bool dbus_register (DBusConnection conn,
                                            string object_path) throws Error {

            this.bus_manager = new DeviceManagerDBusProxy.with_manager (conn,
                                                                        this.manager);
            this.bus_manager.publish ();

            this.bus_transfer = new TransferManagerDBusProxy.with_manager (conn,
                                                                           this.transfer);
            this.bus_transfer.publish ();

            base.dbus_register (conn, object_path);
            debug ("dbus register, path %s", object_path);

            return true;
        }

        public override void dbus_unregister (DBusConnection conn,
                                              string object_path) {

            base.dbus_unregister (conn, object_path);
            debug ("dbus unregister, path %s", object_path);
        }
    }
}