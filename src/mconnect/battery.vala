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

class BatteryHandler : Object, PacketHandlerInterface {

    public const string BATTERY = "kdeconnect.battery";

    public string get_pkt_type () {
        return BATTERY;
    }

    private BatteryHandler () {
    }

    public static BatteryHandler instance () {
        return new BatteryHandler ();
    }

    public void use_device (Device dev) {
        debug ("use device %s for battery status updates", dev.to_string ());
        dev.message.connect (this.message);
    }

    public void release_device (Device dev) {
        debug ("release device %s", dev.to_string ());
        dev.message.disconnect (this.message);
    }

    public void message (Device dev, Packet pkt) {
        if (pkt.pkt_type != BATTERY) {
            return;
        }

        debug ("got battery packet");

        int64 level = pkt.body.get_int_member ("currentCharge");
        bool charging = pkt.body.get_boolean_member ("isCharging");

        debug ("battery level: %u %s", (uint) level,
               (charging == true) ? "charging" : "");
        battery (dev, (uint) level, charging);
    }

    public signal void battery (Device dev, uint level, bool charging);
}