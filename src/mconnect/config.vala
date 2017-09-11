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
public class Config : Object {

	public const string FILE = "mconnect.conf";

	private KeyFile _kf = null;

	public string path { get; private set; default = null; }

	public static string[] config_search_dirs(string primary_dir) {
		string[] dirs = {primary_dir};

		string[] sysdirs = Environment.get_system_data_dirs();
		foreach (string d in sysdirs) {
			dirs += Path.build_path(Path.DIR_SEPARATOR_S,
									d, "mconnect");
		}
		return dirs;
	}

	public Config(string base_config_dir) {

		_kf = new KeyFile();
		string[] dirs = config_search_dirs(base_config_dir);
		string full_path = null;

		foreach (string d in dirs) {
			debug("config search dir: %s", d);
		}

		try {
			bool found = _kf.load_from_dirs(Config.FILE, dirs,
											out full_path,
											KeyFileFlags.KEEP_COMMENTS);
			path = full_path;
			if (found == false) {
				critical("configuration file %s was not found",
						 Config.FILE);
			}
			message("loaded configuration from %s", full_path);
		} catch (KeyFileError ke) {
			critical("failed to parse configuration file: %s", ke.message);
		} catch (FileError fe) {
			critical("failed to read configuration file: %s", fe.message);
		}
	}

	public void dump_to_file(string path) {
		if (_kf == null)
			return;

		string data = _kf.to_data();
		try {
			FileUtils.set_contents(path, data);
		} catch (FileError e) {
			critical("failed to save configuration to %s: %s",
					 path, e.message);
		}
	}

	public bool is_device_allowed(string name, string type) {

		debug("check if device %s type %s is allowed", name, type);
		try {
			string[] devices = _kf.get_string_list("main", "devices");

			foreach (string dev in devices) {
				debug("checking dev %s", dev);
				//
				if (_kf.has_group(dev) == false) {
					debug("no group %s", dev);
					continue;
				}

				if (_kf.get_string(dev, "name") == name &&
					_kf.get_string(dev, "type") == type &&
					_kf.get_boolean(dev, "allowed") == true)
				{
					return true;
				}
			}
		} catch (KeyFileError ke) {
			critical("failed to read entries from configuration file: %s",
					 ke.message);
		}
		return false;
	}

	public bool is_debug_on() {
		try {
			bool debug = _kf.get_boolean("main", "debug");
			return debug;
		} catch (KeyFileError ke) {
			critical("failed to read config entry");
		}
		return false;
	}
}