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
 * James Westman <james@flyingpimonster.net>
 */

class ClipboardHandler : Object, PacketHandlerInterface {
    public const string CLIPBOARD = "kdeconnect.clipboard";

    public string get_pkt_type () {
        return CLIPBOARD;
    }

    private ClipboardHandler () {
    }

    public static ClipboardHandler instance () {
        return new ClipboardHandler ();
    }

    public void use_device (Device dev) {
        debug ("use device %s for clipboard", dev.to_string ());
        dev.message.connect (this.message);
    }

    public void release_device (Device dev) {
        debug ("release device %s", dev.to_string ());
        dev.message.disconnect (this.message);
    }

    public void message (Device dev, Packet pkt) {
        if (pkt.pkt_type != CLIPBOARD) {
            return;
        }

        var content = pkt.body.get_string_member ("content");
        debug ("clipboard content: '%s'", content);

        var display = Gdk.Display.get_default ();
        if (display != null) {
            var cb = Gtk.Clipboard.get_default (display);
            cb.set_text (content, -1);
        }
    }
}
