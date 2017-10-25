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

class FindMyPhoneHandler : Object, PacketHandlerInterface {

    public const string FIND_MY_PHONE = "kdeconnect.findmyphone.request";

    public string get_pkt_type () {
        return FIND_MY_PHONE;
    }

    private FindMyPhoneHandler () {
    }

    public static FindMyPhoneHandler instance () {
        return new FindMyPhoneHandler ();
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
        return;
    }

    private Packet make_find_my_phone_packet () {
        var pkt = new Packet (FIND_MY_PHONE, null);
        return pkt;
    }

    public void ring (Device dev) {
        dev.send (make_find_my_phone_packet ());
    }
}