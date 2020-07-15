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

class PingHandler : Object, PacketHandlerInterface {

    public const string PING = "kdeconnect.ping";

    public string get_pkt_type () {
        return PING;
    }

    private PingHandler () {
    }

    public static PingHandler instance () {
        return new PingHandler ();
    }

    public void use_device (Device dev) {
        debug ("use device %s for ping", dev.to_string ());
        dev.message.connect (this.message);
    }

    public void release_device (Device dev) {
        debug ("release device %s", dev.to_string ());
        dev.message.disconnect (this.message);
    }

    public void message (Device dev, Packet pkt) {
        if (pkt.pkt_type != PING) {
            return;
        }

        GLib.message ("ping from device %s", dev.to_string ());
        ping (dev);
    }

    public void send_ping (Device dev) {
        var pkt = new Packet (PING, new Json.Object ());
        dev.send (pkt);
    }

    public signal void ping (Device dev);
}
