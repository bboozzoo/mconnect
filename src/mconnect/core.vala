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
using Mconn;

class Core : Object {

	public const string APP_NAME = "mconnect";

	public TlsCertificate certificate { get; private set; }

	public PacketHandlers handlers {get; private set; default = null; }

	public Config config { get; private set; default = null; }

	public static string device_id {
		owned get {
			string host_name = Environment.get_host_name();
			string user = Environment.get_user_name();
			return @"$user@host_name";
		}

		private set {}
	}

	public static string device_name {
		owned get {
			return Environment.get_host_name();
		}
		private set {}
	}

	private static Core _instance = null;

	private Core() {
		debug("init core");
	}

	public static Core? instance() {
		if (Core._instance == null)
		{
			init_user_dirs();

			var config = init_config();
			var cert = init_crypto();
			var handlers = new PacketHandlers();

			var core = new Core();
			core.config = config;
			core.certificate = cert;
			core.handlers = handlers;

			info("supported interfaces: %s",
				 string.joinv(", ", handlers.interfaces));
			Core._instance = core;
		}

		return Core._instance;
	}

	public static string get_storage_dir() {
		return Path.build_filename(Environment.get_user_data_dir(),
								   APP_NAME);
	}

	public static string get_config_dir() {
		return Path.build_filename(Environment.get_user_config_dir(),
								   APP_NAME);
	}

	public static string get_cache_dir() {
		return Path.build_filename(Environment.get_user_cache_dir(),
								   APP_NAME);
	}

	private static void init_user_dirs() {
		DirUtils.create_with_parents(get_storage_dir(), 0700);
		DirUtils.create_with_parents(get_config_dir(), 0700);
	}

	private static TlsCertificate init_crypto() throws Error {
		var key_file = File.new_for_path(Path.build_filename(get_storage_dir(),
															 "private.pem"));
		var cert_file = File.new_for_path(Path.build_filename(get_storage_dir(),
															  "certificate.pem"));
		if (key_file.query_exists() == false || cert_file.query_exists() == false) {
			try {
				Crypt.generate_key_cert(key_file.get_path(),
										cert_file.get_path(),
										Core.device_name);
			} catch (Error e) {
				warning("failed to generate private key or certificate: %s", e.message);
				throw e;
			}
		}

		TlsCertificate tls_cert;
		try {
			tls_cert = new TlsCertificate.from_files(cert_file.get_path(),
													 key_file.get_path());
		} catch (Error e) {
			warning("failed to load certificate or key: %s", e.message);
			throw e;
		}
		return tls_cert;
	}

	private static Config init_config() {
		string user_config_path = get_config_dir() + "/" + Config.FILE;

		var config = new Config(get_config_dir());

		// write configuration to user config file if none is present
		if (config.path != user_config_path) {
			config.dump_to_file(user_config_path);
		}

		return config;
	}

}