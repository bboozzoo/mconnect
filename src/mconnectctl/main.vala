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

namespace Mconnect {

	[DBus (name = "org.mconnect.DeviceManager")]
	public interface DeviceManagerIface : Object {

		public const string OBJECT_PATH = "/org/mconnect/manager";

		public abstract ObjectPath[] ListDevices() throws IOError;
		public abstract void AllowDevice(string path) throws IOError;
	}

	[DBus (name = "org.mconnect.Device")]
	public interface DeviceIface : Object {

		public abstract string id { owned get;}
		public abstract string name { owned get;}
		public abstract string device_type  { owned get;}
		public abstract uint protocol_version  { owned get;}
		public abstract string address  { owned get;}
		public abstract bool is_paired  { owned get;}
		public abstract bool allowed { owned get;}
		public abstract bool is_active { owned get;}
		public abstract bool is_connected { owned get;}
		public abstract string[] outgoing_capabilities { owned get;}
		public abstract string[] incoming_capabilities { owned get;}
	}

	public class Client {

		private static bool log_debug = false;
		private static bool verbose = false;
		// some hints for valac about the array holding remaining args
		[CCode (array_length = false, array_null_terminated = true)]
		private static string[] remaining;
		private BusType bus_type = BusType.SESSION;

		private const OptionEntry[] options = {
			{"debug", 'd', 0, OptionArg.NONE, ref log_debug,
			 "Show debug output", null},
			{"verbose", 'v', 0, OptionArg.NONE, ref verbose,
			 "Be verbose", null},
			// there's no Vala const for G_OPTION_REMAINING (which is a #define
			// for "")
			{"", 0, 0, OptionArg.STRING_ARRAY, ref remaining, null,
			 "[COMMAND ..]"},
			{null}
		};

		/**
		 * Command:
		 *
		 * command line 'command' wrapper
		 */
		private struct Command {
			string command;		// textual command, ex. list, show, etc.
			int arg_count;		// number of required parameters, not including
								// command
			unowned CommandFunc clbk; // callback

			Command(string command, int arg_count, CommandFunc clbk) {
				this.command = command;
				this.arg_count = arg_count;
				this.clbk = clbk;
			}
		}
		// command callback
		private delegate int CommandFunc(string[] args);

		public static int main(string[] args)
		{
			try {
				var opt_context = new OptionContext();
				opt_context.set_description(
					"""Available commands:
  list-devices         List devices
  allow-device <path>  Allow device
  show-device <path>   Show device details
"""
					);
				opt_context.set_help_enabled(true);
				opt_context.add_main_entries(options, null);
				opt_context.parse(ref args);
			} catch (OptionError e) {
				stdout.printf("error: %s\n", e.message);
				stdout.printf("Run '%s --help' to see a full " +
							  "list of available command line options.\n",
							  args[0]);
				return 1;
			}

			if (log_debug == true)
				Environment.set_variable("G_MESSAGES_DEBUG", "all", false);

			var cl = new Client();

			Command[] commands = {
				Command("list-devices", 0, cl.cmd_list_devices),
				Command("allow-device", 1, cl.cmd_allow_device),
				Command("show-device", 1, cl.cmd_show_device),
			};
			handle_command(remaining, commands);

			return 0;
		}

		/**
		 * handle_command:
		 * @args: remaining command line arguments
		 * @commands: supported commands array
		 *
		 * @return exit status of command or -1 on error
		 */
		private static int handle_command(string[] args, Command[] commands) {
			// extract command and it's arguments if any
			string command = "list-devices";

			if (args.length > 0)
				command = remaining[0];
			debug("command is: %s", command);

			string[] command_args = {};
			if (args.length > 1)
				command_args = args[1:args.length];

			foreach (var cmden in commands) {
				if (cmden.command == command) {
					debug("found match for %s, args expect: %zd, have: %zd",
						  command, cmden.arg_count, command_args.length);

					if (command_args.length != cmden.arg_count) {
						stderr.printf("Incorrect number of arguments " +
									  "for command %s, see --help\n",
									  command);
						return -1;
					}

					debug("running callback");
					return cmden.clbk(command_args);
				}
			}

			stderr.printf("Incorrect command, see --help\n");
			return -1;
		}

		private int cmd_list_devices(string[] args) {
			return checked_dbus_call(() => {
					var manager = get_manager();
					debug("list devices");
					var devs = manager.ListDevices();
					print_paths(devs, "Devices",
								(path) => {
									try {
										var dp = get_device(path);
										return "%s - %s".printf(dp.id, dp.name);
									} catch (IOError e) {
										warning("error occurred: %s", e.message);
										return "(error)";
									}
								});
					return 0;
				});
			}

		private int cmd_allow_device(string[] args) {
			return checked_dbus_call(() => {
					var dp = args[0];
					var manager = get_manager();
					debug("allow device device %s", dp);
					manager.AllowDevice(new ObjectPath(dp));
					return 0;
				});
		}

		private void print_sorted_caps(string[] caps, string format) {
			qsort_with_data<string>(caps, sizeof(string),
									(a, b) => GLib.strcmp(a, b));
			foreach (var cap in caps) {
				stdout.printf(format, cap);
			}
		}

		private int cmd_show_device(string[] args) {
			return checked_dbus_call(() => {
					var dp = get_device(new ObjectPath(args[0]));

					stdout.printf("Device\n" +
								  "  Name: %s\n" +
								  "  ID: %s\n" +
								  "  Address: %s\n" +
								  "  Type: %s\n" +
								  "  Allowed: %s\n" +
								  "  Paired: %s\n" +
								  "  Active: %s\n" +
								  "  Connected: %s\n",
								  dp.name,
								  dp.id,
								  dp.address,
								  dp.device_type,
								  dp.allowed.to_string(),
								  dp.is_paired.to_string(),
								  dp.is_active.to_string(),
								  dp.is_connected.to_string());
					if (verbose) {
						stdout.printf("  Capabilities (out):\n");
						print_sorted_caps(dp.outgoing_capabilities, "    %s\n");
						stdout.printf("  Capabilities (in):\n");
						print_sorted_caps(dp.incoming_capabilities, "    %s\n");
					}
					return 0;
				});
		}

		private delegate int CheckDBusCallFunc() throws Error;
		/**
		 * checked_dbus_call:
		 * @clbk: function to wrap
		 *
		 * Catch any DBus errors and return appropriate status
		 */
		private static int checked_dbus_call(CheckDBusCallFunc clbk) {
			try {
				return clbk();
			} catch (IOError e) {
				warning("communication returned an error: %s", e.message);
				return -1;
			} catch (DBusError e) {
				warning("communication with service failed: %s", e.message);
			} catch (Error e) {
				warning("error: %s", e.message);
			}
			return 0;
		}

		/**
		 * get_mconnect_obj_proxy:
		 * @path: DBus object path
		 *
		 * Obtain an interface to a DBus object avaialble at
		 * Mconnect service under @path.
		 *
		 * @return null or interface
		 */
		private T? get_mconnect_obj_proxy<T>(ObjectPath path) throws IOError {
			T proxy_out = null;
			try {
				proxy_out = Bus.get_proxy_sync(bus_type,
											   "org.mconnect",
											   path);
			} catch (IOError e) {
				warning("failed to obtain proxy to mconnect service: %s",
						e.message);
				throw e;
			}
			return proxy_out;
		}

		/**
		 * get_manager:
		 *
		 * Obtain DBus interface to Device Manager
		 *
		 * @return interface or null
		 */
		private DeviceManagerIface? get_manager() throws IOError {
			return get_mconnect_obj_proxy(
				new ObjectPath(DeviceManagerIface.OBJECT_PATH));
		}

		/**
		 * get_device:
		 * @path device object path
		 *
		 * Obtain DBus interface to Device
		 *
		 * @return interface or null
		 */
		private DeviceIface? get_device(ObjectPath path) throws IOError {
			return get_mconnect_obj_proxy(path);
		}

		/**
		 * print_paths:
		 * @objs: object paths
		 * @header: header for printing,
		 * @desc_clbk: callback for producing a meaningful description
		 *
		 * Print a list of object paths, possibly adding a description
		 */
		private static void print_paths(ObjectPath[] objs, string header,
										GetDescFunc desc_clbk) {
			if (objs.length == 0)
				stdout.printf("No objects were found\n");
			else {
				stdout.printf(header + ":\n");
				foreach (var o in objs) {
					string desc = null;

					if (desc_clbk != null) {
						debug("calling description callback for obj: %s",
							  o.to_string());
						desc = desc_clbk(o);
					}

					stdout.printf("    %s", o.to_string());
					if (desc != null)
						stdout.printf("    %s", desc);
					stdout.printf("\n");
				}
			}
		}

		private delegate string GetDescFunc(ObjectPath obj_path);
	}
}
