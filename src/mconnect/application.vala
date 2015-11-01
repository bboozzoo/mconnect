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

namespace Mconn {

	public class Application : GLib.Application {

		private Core core = null;

		private static bool log_debug = false;

		private const GLib.OptionEntry[] options = {
			{"debug", 'd', 0, OptionArg.NONE, ref log_debug, "Show debug output", null},
			{null}
		};

		public Application() {
			Object(application_id: "org.bboozzoo.mconnect");
			add_main_option_entries(options);
		}

		protected override void startup() {
			base.startup();

			if (log_debug == true)
				Environment.set_variable("G_MESSAGES_DEBUG", "all", false);

			core = Core.instance();
			if (core == null)
				error("cannot initialize core");

			if (core.config.is_debug_on() == true)
				Environment.set_variable("G_MESSAGES_DEBUG", "all", false);

			Notify.init("mconnect");

			var discovery = new Discovery();
			var manager = new DeviceManager();

			discovery.device_found.connect((disc, dev) => {
					manager.found_device(dev);
				});
			try {
				discovery.listen();
			} catch (Error e) {
				message("failed to setup device listener: %s", e.message);
			}
		}

		protected override void activate() {
			hold();
		}
	}
}