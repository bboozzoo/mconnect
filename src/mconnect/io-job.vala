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
using Logging;

class IOCopyJob : Object {

    private InputStream from = null;
    private OutputStream to = null;

    public IOCopyJob (InputStream from, OutputStream to) {
        this.from = from;
        this.to = to;
    }

    /**
     * transfer_async:
     * @cancel: cancellable
     *
     * Starty asynchronous transfer of data from @from stream to @to stream.
     *
     * @return number of bytes transferred if no error occurred
     */
    public async uint64 start_async (Cancellable ? cancel) throws Error {
        uint64 bytes_done = 0;
        var chunk_size = 4096;
        var max_chunk_size = 64 * 1024;
        while (true) {
            var data = yield this.from.read_bytes_async (chunk_size,
                                                         Priority.DEFAULT,
                                                         cancel);

            vdebug ("read %d bytes", data.length);
            if (data.length == 0) {
                break;
            }

            // XXX: write_bytes_async will not always write the whole buffer.
            yield this.to.write_all_async (data.get_data (), Priority.DEFAULT, cancel, null);

            bytes_done += data.length;
            this.progress (bytes_done);

            if (data.length == chunk_size)
                chunk_size = 2 * chunk_size;

            if (chunk_size > max_chunk_size)
                chunk_size = max_chunk_size;
        }

        debug ("transfer done, got %s bytes", format_size (bytes_done));
        return bytes_done;
    }

    /**
     * progress:
     * @bytes_down: number of bytes transferred
     *
     * Indicate transfer progress
     */
    public signal void progress (uint64 bytes_done);
}