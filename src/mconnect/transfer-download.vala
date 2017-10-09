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

class DownloadTransfer : TransferInterface, Object {

	private InetSocketAddress isa = null;
	private File file = null;
	private FileOutputStream foutstream = null;
	private Cancellable cancellable = null;
	private SocketConnection conn = null;
	private TlsConnection tls_conn = null;
	public uint64 size = 0;
	public uint64 transferred = 0;
	public string destination = "";
	private IOCopyJob job = null;
	private Device device = null;

	public DownloadTransfer(Device dev, InetSocketAddress isa,
							uint64 size, string dest) {
		this.isa = isa;
		this.cancellable = new Cancellable();
		this.destination = dest;
		this.size = size;
		this.device = dev;
	}

	public async bool start_async() {
		try {
			this.file = File.new_for_path(this.destination + ".part");
			this.foutstream = this.file.replace(null, false,
				FileCreateFlags.PRIVATE | FileCreateFlags.REPLACE_DESTINATION);
		} catch (Error e) {
			warning("failed to open destination path %s: %s",
					this.destination, e.message);
			return false;
		}

		debug("start transfer from %s:%u",
			  this.isa.address.to_string(), this.isa.port);
		var client = new SocketClient();

		try {
			this.conn = yield client.connect_async(this.isa);
			debug("connected");
		} catch (Error e) {
			var err ="failed to connect: %s".printf(e.message);
			warning(err);
			this.cleanup_error(err);
			return false;
		}

		var sock = this.conn.get_socket();
		Utils.socket_set_keepalive(sock);

		// enable TLS
		this.tls_conn = Utils.make_tls_connection(this.conn,
												  Core.instance().certificate,
												  this.device.certificate,
												  Utils.TlsConnectionMode.CLIENT);
		try {
			debug("attempt TLS handshake");
			var tls_res = yield this.tls_conn.handshake_async();
			debug("TLS handshake complete");
		} catch (Error e) {
			var err ="TLS handshake failed: %s".printf(e.message);
			warning(err);
			this.cleanup_error(err);
			return false;
		}

		this.start_transfer();
		return true;
	}

	private void start_transfer() {
		debug("connected, start transfer");
		this.job = new IOCopyJob(this.tls_conn.input_stream,
									  this.foutstream);
		this.job.progress.connect((t, done) => {
				int percent = (int) (100.0 * ((double)done / (double)this.size));
				debug("progress: %s/%s %d%%",
					  format_size(done), format_size(this.size), percent);
				this.transferred = done;
			});

		this.started();

		this.job.start_async.begin(this.cancellable,
								   this.job_complete);
	}

	private void job_complete(Object? obj, AsyncResult res) {
		info("transfer finished");
		try {
			var rcvd_bytes = this.job.start_async.end(res);
			debug("transfer done, got %s", format_size(rcvd_bytes));

			this.cleanup_success();

		} catch (Error err) {
			warning("transfer failed: %s", err.message);

			this.cleanup_error(err.message);
		}
	}

	private void cleanup() {
		if (this.foutstream != null) {
			try {
				this.foutstream.close();
			} catch (IOError e) {
				warning("failed to close file output: %s",
						e.message);
			}
		}

		if (this.tls_conn != null) {
			try {
				this.tls_conn.close();
			} catch (IOError e) {
				warning("failed to close TLS connection: %s",
						e.message);
			}
		}
		if (this.conn != null) {
			try {
				this.conn.close();
			} catch (IOError e) {
				warning("failed to close connection: %s",
						e.message);
			}
		}

		this.file = null;
		this.foutstream = null;
		this.conn = null;
		this.tls_conn = null;
		this.job = null;
	}

	private void cleanup_error(string reason) {

		this.file.@delete();

		this.cleanup();

		this.error(reason);
	}

	private void cleanup_success() {
		try {
			var dest = File.new_for_path(this.destination);
			this.file.move(dest, FileCopyFlags.OVERWRITE);

			this.cleanup();

			this.finished();

		} catch (Error e) {
			var err = "failed to rename temporary file %s to %s: %s".printf(this.file.get_path(),
																			this.destination,
																			e.message);
			warning(err);
			this.cleanup_error(err);
		}
	}

	public void cancel() {
		debug("cancel called");
		this.cancellable.cancel();
	}
}