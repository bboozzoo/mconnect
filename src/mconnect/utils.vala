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

namespace Utils {

    using Posix;

    /**
     * make_unique_device_string:
     * @id: device ID
     * @name: device name
     * @type: device type
     * @pv: protocol version
     *
     * Generate device string that can be used as map index
     */
    string make_unique_device_string (string id, string name,
                                      string type, uint pv) {
        return make_device_string (id, name, type, pv).replace (" ", "-");
    }

    /**
     * make_device_string:
     * @id: device ID
     * @name: device name
     * @type: device type
     * @pv: protocol version
     *
     * Generate device string
     */
    string make_device_string (string id, string name,
                               string type, uint pv) {
        return "%s-%s-%s-%u".printf (id, name, type, pv);
    }

    /**
     * socket_set_keepalive:
     * @sock: socket
     *
     * Set keepalive counters on socket
     */
    void socket_set_keepalive (Socket sock) {
#if 0
        IPPROTO_TCP = 6, /* Transmission Control Protocol.  */

        TCP_KEEPIDLE     4 /* Start keeplives after this period */
        TCP_KEEPINTVL    5 /* Interval between keepalives */
        TCP_KEEPCNT              6 /* Number of keepalives before death */
#endif
#if 0
        int option = 10;
        Posix.setsockopt (sock.fd, 6, 4, &option, (Posix.socklen_t) sizeof (int));
        option = 5;
        Posix.setsockopt (sock.fd, 6, 5, &option, (Posix.socklen_t) sizeof (int));
        option = 3;
        Posix.setsockopt (sock.fd, 6, 6, &option, (Posix.socklen_t) sizeof (int));
#endif
        int option = 10;
        Posix.setsockopt (sock.fd, IPProto.TCP,
                          Posix.TCP_KEEPIDLE,
                          &option, (Posix.socklen_t) sizeof (int));
        option = 5;
        Posix.setsockopt (sock.fd, IPProto.TCP,
                          Posix.TCP_KEEPINTVL,
                          &option, (Posix.socklen_t) sizeof (int));
        option = 3;
        Posix.setsockopt (sock.fd, IPProto.TCP,
                          Posix.TCP_KEEPCNT,
                          &option, (Posix.socklen_t) sizeof (int));

        // enable keepalive
        sock.set_keepalive (true);
    }

    public enum TlsConnectionMode {
        SERVER,
        CLIENT,
    }
    /**
     * make_tls_connection:
     *
     * Create a TLS connection around given connected socket.
     * When @expected_peer is non-null, the handshake will be rejected if the
     * certificate presented by peer is different from expected.
     *
     * @sock_conn: connected socket
     * @self_cert: own certificate
     * @expected_peer: expected peer certificate
     * @is_client_connection: if true then TLS client side connection is prepared
     *
     * @return new TlsConnection
     */
    TlsConnection make_tls_connection (SocketConnection sock_conn,
                                       TlsCertificate self_cert,
                                       TlsCertificate ? expected_peer = null,
                                       TlsConnectionMode mode = TlsConnectionMode.SERVER) throws Error {
        TlsConnection tls_conn;

        if (mode == TlsConnectionMode.SERVER) {
            debug ("creating TLS server connection");
            var tls_serv = TlsServerConnection.@new (sock_conn, self_cert);
            tls_serv.authentication_mode = TlsAuthenticationMode.REQUESTED;
            tls_conn = tls_serv;
        } else {
            debug ("creating TLS client connection");
            tls_conn = TlsClientConnection.@new (sock_conn,
                                                 sock_conn.get_remote_address ());
            tls_conn.set_certificate (self_cert);
        }
        tls_conn.accept_certificate.connect ((peer_cert, errors) => {
            info ("accept certificate, flags: 0x%x", errors);
            info ("certificate:\n%s\n", peer_cert.certificate_pem);

            if (expected_peer != null) {
                if (Logging.VERBOSE) {
                    vdebug ("verify certificate, expecting: %s, got: %s",
                            expected_peer.certificate_pem,
                            peer_cert.certificate_pem);
                }

                if (expected_peer.is_same (peer_cert)) {
                    return true;
                } else {
                    warning ("rejecting handshare, peer certificate mismatch, got:\n%s",
                             peer_cert.certificate_pem);
                    return false;
                }
            }
            return true;
        });
        return tls_conn;
    }

    /**
     * find_urls:
     *
     * Locate and extract URL like patterns in the text. URLs are assumed to
     * start with http or https.
     *
     * @text: input test
     * @return array of matches, if there were none then array if of length 0
     */
    string[] find_urls (string text) {
        try {

            // regex taken from SO
            // uncrustify breaks the regex, so *INDENT-OFF*
			GLib.Regex r = /https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+,.~#?&\/=]*)/;
            // *INDENT-ON*

            MatchInfo mi;

            string[] matches = {};

            if (r.match (text, RegexMatchFlags.NOTEMPTY, out mi)) {
                while (mi.matches ()) {
                    if (mi.is_partial_match () == false) {
                        var m = mi.fetch (0);
                        debug ("found match %s", m);
                        matches += m;
                    }
                    mi.next ();
                }
            } else {
                debug ("no match");
            }
            return matches;
        } catch (GLib.RegexError e) {
            warning ("failed to compile regex: %s", e.message);
            return {};
        }
    }

    public void show_own_notification (string message,
                                       string summary = "mconnect",
                                       string icon = "dialog-information") {
        try {
            var notif = new Notify.Notification (summary, message,
                                                 "phone");
            notif.show ();
        } catch (Error e) {
            critical ("failed to show notification: %s", e.message);
        }
    }
}
