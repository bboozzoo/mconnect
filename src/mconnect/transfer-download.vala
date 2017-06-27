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

class DownloadTransfer : Object {

	private InetSocketAddress isa = null;
	private File file = null;
	private FileOutputStream foutstream = null;
	private Cancellable cancel = null;
	private SocketConnection conn = null;
	public uint64 size = 0;
	public uint64 transferred = 0;
	public string destination = "";
	private Transfer transfer = null;

	public DownloadTransfer(InetSocketAddress isa, uint64 size, string dest) {
		this.isa = isa;
		this.cancel = new Cancellable();
		this.destination = dest;
		this.size = size;
	}

	public bool start() {
		try {
			this.file = File.new_for_path(this.destination + ".part");
			this.foutstream = this.file.replace(null, false,
				FileCreateFlags.PRIVATE | FileCreateFlags.REPLACE_DESTINATION);
		} catch (Error e) {
			warning("failed to open destination path %s: %s",
					this.destination, e.message);
			return false;
		}

		var client = new SocketClient();
		client.connect_async.begin(this.isa, null, this.connected);
		return true;
	}

	private void connected(Object? obj, AsyncResult res) {
		try {
			var sc = (SocketClient)obj;
			this.conn = sc.connect_async.end(res);

			var sock = this.conn.get_socket();
			Utils.socket_set_keepalive(sock);
			this.start_transfer();

		} catch (Error e) {
			var err ="failed to connect: %s".printf(e.message);
			warning(err);
			this.cleanup_error(err);
		}
	}

	private void start_transfer() {
		this.transfer = new Transfer(this.conn.input_stream,
									 this.foutstream);
		this.transfer.progress.connect((t, p) => {
				int percent = (int) (100.0 * ((double)p / (double)this.size));
				debug("progress: %llu/%llu %d %%", p, this.size, percent);
			});
		this.transfer.transfer_async.begin(this.cancel,
										   this.transfer_complete);
	}

	private void transfer_complete(Object? obj, AsyncResult res) {
		info("transfer finished");
		try {
			var rcvd_bytes = this.transfer.transfer_async.end(res);
			debug("transfer done, got %llu bytes", rcvd_bytes);

			this.cleanup_success();

		} catch (IOError err) {
			warning("transfer failed: %s", err.message);

			this.cleanup_error(err.message);
		}
	}

	private void cleanup() {
		if (this.foutstream != null)
			this.foutstream.close();

		this.file = null;
		this.foutstream = null;
		this.transfer = null;
	}

	private void cleanup_error(string reason) {

		this.file.@delete();

		this.cleanup();

		this.error(reason);
	}

	private void cleanup_success() {

		var failed = false;
		try {
			var dest = File.new_for_path(this.destination);
			this.file.move(dest, FileCopyFlags.OVERWRITE);

			this.cleanup();

			this.finished();

		} catch (IOError e) {
			var err = "failed to rename temporary file %s to %s: %s".printf(this.file.get_path(),
																			this.destination,
																			e.message);
			warning(err);
			this.cleanup_error(err);
		}
	}

	public signal void finished();
	public signal void error(string reason);
}