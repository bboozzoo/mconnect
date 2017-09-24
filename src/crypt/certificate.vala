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

	namespace Crypt {

		private GnuTLS.X509.PrivateKey generate_private_key() {
			var key = GnuTLS.X509.PrivateKey.create();

			key.generate(GnuTLS.PKAlgorithm.RSA, 2048);
			// size_t sz = 4096;
			// var buf = GnuTLS.malloc(sz);
			// key.export_pkcs8(GnuTLS.X509.CertificateFormat.PEM, "",
			// 				 GnuTLS.X509.PKCSEncryptFlags.PLAIN,
			// 				 buf, ref sz);

			// stdout.printf("private key:\n");
			// stdout.printf("%s", (string)buf);

			// GnuTLS.free(buf);

			return key;
		}

		private struct dn_setting {
			string oid;
			string name;
		}

		GnuTLS.X509.Certificate generate_self_signed_cert(GnuTLS.X509.PrivateKey key, string common_name) {

			var cert = GnuTLS.X509.Certificate.create();
			var start_time = new DateTime.now_local();
			var end_time = start_time.add_years(10);

			cert.set_key(key);
			cert.set_version(1);
			cert.set_activation_time((time_t)start_time.to_unix());
			cert.set_expiration_time((time_t)end_time.to_unix());
			uint32 serial = Posix.htonl(10);
			cert.set_serial(&serial, sizeof(uint32));

			dn_setting[] dn = {
				dn_setting() { oid=GnuTLS.OID.X520_ORGANIZATION_NAME,
							   name="mconnect"},
				dn_setting() { oid=GnuTLS.OID.X520_ORGANIZATIONAL_UNIT_NAME,
							   name="mconnect"},
				dn_setting() { oid=GnuTLS.OID.X520_COMMON_NAME,
							   name=common_name},
			};
			foreach (var dn_val in dn) {
				var err = cert.set_dn_by_oid(dn_val.oid, 0,
											 dn_val.name.data, dn_val.name.length);
				if (err != GnuTLS.ErrorCode.SUCCESS ) {
					warning("set dn failed for OID %s - %s, err: %d\n",
							dn_val.oid, dn_val.name, err);
				}
			}


			var err = cert.sign(cert, key);
			GLib.assert(err == GnuTLS.ErrorCode.SUCCESS);

			// size_t sz = 8192;
			// var buf = GnuTLS.malloc(sz);
			// err = cert.export(GnuTLS.X509.CertificateFormat.PEM, buf, ref sz);
			// if (err != GnuTLS.ErrorCode.SUCCESS) {
			// 	if (err == GnuTLS.ErrorCode.SHORT_MEMORY_BUFFER) {
			// 		stdout.printf("too short\n");
			// 	} else {
			// 		stdout.printf("other error: %d\n", err);
			// 	}
			// } else {
			// 	stdout.printf("certificate:\n");
			// 	stdout.printf("size: %zu\n", sz);
			// 	stdout.printf("%s", (string)buf);
			// }
			// GnuTLS.free(buf);

			return cert;
		}

		private uint8[] export_certificate(GnuTLS.X509.Certificate cert) {
			var buf = new uint8[8192];
			size_t sz = buf.length;


			var err = cert.export(GnuTLS.X509.CertificateFormat.PEM, buf, ref sz);
			assert(err == GnuTLS.ErrorCode.SUCCESS);

			debug("actual certificate PEM size: %zu", sz);
			debug("certificate PEM:\n%s", (string)buf);

			// TODO: figure out if this is valid at all
			buf.length = (int) sz;

			return buf;
		}

		private uint8[] export_private_key(GnuTLS.X509.PrivateKey key) {
			var buf = new uint8[8192];
			size_t sz = buf.length;

			var err = key.export_pkcs8(GnuTLS.X509.CertificateFormat.PEM, "",
									   GnuTLS.X509.PKCSEncryptFlags.PLAIN,
									   buf, ref sz);
			assert(err == GnuTLS.ErrorCode.SUCCESS);
			debug("actual private key PEM size: %zu", sz);
			debug("private key PEM:\n%s", (string)buf);

			// TODO: figure out if this is valid at all
			buf.length = (int) sz;
			return buf;
		}

		private void export_to_file(string path, uint8[] data) throws Error {
			var f = File.new_for_path(path);

			f.replace_contents(data, "", false,
							   FileCreateFlags.PRIVATE | FileCreateFlags.REPLACE_DESTINATION,
							   null);
		}

		public void generate_key_cert(string key_path, string cert_path, string name) throws Error {
			var key = generate_private_key();
			var cert = generate_self_signed_cert(key, name);

			export_to_file(cert_path, export_certificate(cert));
			export_to_file(key_path, export_private_key(key));
		}
	}
}