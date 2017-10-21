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

class TransferManager : Object {

    public const uint16 PORT_MIN = 9970;
    public const uint16 PORT_MAX = 9975;

    public signal void new_transfer (TransferInterface job);

    public TransferManager () {
    }

    public void push_job (TransferInterface job) {
        debug ("new transfer job");
        new_transfer (job);
    }

    public SocketService ? make_listener (out uint16 listen_port) {
        var ss = new SocketService ();
        for (var port = PORT_MIN; port <= PORT_MAX; port++) {
            var added = false;
            try {
                added = ss.add_inet_port (port, null);
            } catch (Error e) {
                if (e is IOError.ADDRESS_IN_USE) {
                    warning ("port %u in use, trying another", port);
                }
            }
            if (added == true) {
                debug ("allocated listener on port %u", port);
                listen_port = port;
                return ss;
            }
        }
        ss.close ();
        warning ("could not find a free port to listen on");
        return null;
    }
}