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

class MousepadHandler : Object, PacketHandlerInterface {

    public const string MOUSEPAD = "kdeconnect.mousepad.request";
    public const string MOUSEPAD_PACKET = "kdeconnect.mousepad";

    private Gdk.Display _display;

    public string get_pkt_type () {
        return MOUSEPAD;
    }

    private MousepadHandler () {
    }

    public static MousepadHandler instance () {
        var ms = new MousepadHandler ();

        if (Atspi.init () > 1) {
            warning ("failed to initialize AT-SPI");
        }
        ms._display = Gdk.Display.get_default ();
        if (ms._display == null) {
            warning ("failed to obtain display");
        }
        return ms;
    }

    public void use_device (Device dev) {
        debug ("use device %s for mouse/keyboard input", dev.to_string ());
        dev.message.connect (this.message);
    }

    public void release_device (Device dev) {
        debug ("release device %s ", dev.to_string ());
        dev.message.disconnect (this.message);
    }

    private void message (Device dev, Packet pkt) {
        if (pkt.pkt_type != MOUSEPAD_PACKET && pkt.pkt_type != MOUSEPAD) {
            return;
        }

        debug ("got mousepad packet");

        if (_display == null) {
            warning ("display not initialized");
            return;
        }
        if (pkt.body.has_member ("singleclick")) {
            // single click
            debug ("single click");
            send_click (1);
        } else if (pkt.body.has_member ("doubleclick")) {
            send_click (1, true);
        } else if (pkt.body.has_member ("rightclick")) {
            send_click (3);
        } else if (pkt.body.has_member ("middleclick")) {
            send_click (2);
        } else if (pkt.body.has_member ("dx") && pkt.body.has_member ("dy")) {
            // motion/position or scrolling
            double dx = pkt.body.get_double_member ("dx");
            double dy = pkt.body.get_double_member ("dy");

            if (pkt.body.has_member ("scroll") && pkt.body.get_boolean_member ("scroll")) {
                // scroll with variable speed
                while (dy > 3.0) {
                    // scroll down
                    send_click (5);
                    dy /= 4.0;
                    debug ("scroll down");
                }
                while (dy < -3.0) {
                    // scroll up
                    send_click (4);
                    dy /= 4.0;
                    debug ("scroll up");
                }
            } else {
                debug ("position: %f x %f", dx, dy);

                move_cursor_relative (dx, dy);
            }
        } else if (pkt.body.has_member ("key")) {
            string key = pkt.body.get_string_member ("key");
            debug ("got key: %s", key);
            send_key (key);
        } else if (pkt.body.has_member ("specialKey")) {
            var keynum = pkt.body.get_int_member ("specialKey");
            debug ("got special key: %s", keynum.to_string ());
            send_keysym ((uint) keynum);
        }
    }

    private void move_cursor_relative (double dx, double dy) {
        try {
            Atspi.generate_mouse_event ((long) dx, (long) dy, "rel");
        } catch (Error e) {
            warning ("failed to generate mouse move event: %s", e.message);
        }
    }

    private void send_click (int button, bool doubleclick = false) {
        var etype = "b%ic".printf (button);
        try {
            int x, y;
            _display.get_pointer (null, out x, out y, null);
            Atspi.generate_mouse_event (x, y, etype);
            if (doubleclick) {
                Atspi.generate_mouse_event (x, y, etype);
            }
        } catch (Error e) {
            warning ("failed to generate mouse click event: %s", e.message);
        }
    }

    private void send_key (string key) {
        try {
            Atspi.generate_keyboard_event (0, key,
                                           Atspi.KeySynthType.STRING);
        } catch (Error e) {
            warning ("failed to generate keyboard event: %s", e.message);
        }
    }

    private void send_keysym (uint key) {
        uint keyval = 0;
        if (key == 12) {
            keyval = Gdk.keyval_from_name ("Return");
        } else if (key == 1) {
            keyval = Gdk.keyval_from_name ("BackSpace");
        }

        if (keyval == 0) {
            warning ("could not identify key %u", key);
            return;
        }

        debug ("keyval %x %s", keyval, Gdk.keyval_name (keyval));
        try {
            Atspi.generate_keyboard_event (keyval, null,
                                           Atspi.KeySynthType.PRESSRELEASE
                                           | Atspi.KeySynthType.SYM);
        } catch (Error e) {
            warning ("failed to generate keyboard event: %s", e.message);
        }
    }
}