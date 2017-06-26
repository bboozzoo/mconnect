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

class Transfer : Object {

	private InputStream from = null;
	private OutputStream to = null;

	public Transfer(InputStream from, OutputStream to) {
		this.from = from;
		this.to = to;
	}

	public async uint64 transfer_async(Cancellable? cancel) throws IOError {
		uint64 bytes_done = 0;
		var chunk_size = 4096;
		var max_chunk_size = 64 * 1024;
		while (true) {
			var data = yield this.from.read_bytes_async(chunk_size);
			debug("read %d bytes", data.length);
			if (data.length == 0) {
				break;
			}
			yield this.to.write_bytes_async(data);
			bytes_done += data.length;
			this.progress(bytes_done);

			if (data.length == chunk_size)
				chunk_size = 2 * chunk_size;

			if (chunk_size > max_chunk_size)
				chunk_size = max_chunk_size;
		}

		debug("transfer done, got %llu bytes", bytes_done);
		this.from.close();
		this.to.close();

		return bytes_done;
	}

	public signal void progress(uint64 bytes_done);
}