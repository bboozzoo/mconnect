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

class ShareHandler : Object, PacketHandlerInterface {

    public const string SHARE = "kdeconnect.share.request";
    public const string SHARE_PKT = "kdeconnect.share";
    private static string DOWNLOADS = null;

    public void use_device (Device dev) {
        debug ("use device %s for sharing", dev.to_string ());
        dev.message.connect (this.message);
    }

    private ShareHandler () {
    }

    public static ShareHandler instance () {
        if (ShareHandler.DOWNLOADS == null) {

            ShareHandler.DOWNLOADS = Path.build_filename (
                Environment.get_user_special_dir (UserDirectory.DOWNLOAD),
                "mconnect");

            if (DirUtils.create_with_parents (ShareHandler.DOWNLOADS,
                                              0700) == -1) {
                warning ("failed to create downloads directory: %s",
                         Posix.strerror (Posix.errno));
            }
        }

        info ("downloads will be saved to %s", ShareHandler.DOWNLOADS);
        return new ShareHandler ();
    }

    private static string make_downloads_path (string name) {
        return Path.build_filename (ShareHandler.DOWNLOADS, name);
    }

    public string get_pkt_type () {
        return SHARE;
    }

    public void release_device (Device dev) {
        debug ("release device %s", dev.to_string ());
        dev.message.disconnect (this.message);
    }

    private void message (Device dev, Packet pkt) {
        if (pkt.pkt_type != SHARE_PKT && pkt.pkt_type != SHARE) {
            return;
        }

        if (pkt.body.has_member ("filename")) {
            this.handle_file (dev, pkt);
        } else if (pkt.body.has_member ("url")) {
            this.handle_url (dev, pkt);
        } else if (pkt.body.has_member ("text")) {
            this.handle_text (dev, pkt);
        }
    }

    private void handle_file (Device dev, Packet pkt) {
        if (pkt.payload == null) {
            warning ("missing payload info");
            return;
        }

        string name = pkt.body.get_string_member ("filename");
        debug ("file: %s size: %s", name, format_size (pkt.payload.size));

        var t = new DownloadTransfer (
            dev,
            new InetSocketAddress (dev.host,
                                   (uint16) pkt.payload.port),
            pkt.payload.size,
            make_downloads_path (name));

        Core.instance ().transfer_manager.push_job (t);

        t.start_async.begin ();
    }

    private void handle_url (Device dev, Packet pkt) {
        var url_msg = pkt.body.get_string_member ("url");

        var urls = Utils.find_urls (url_msg);
        if (urls.length > 0) {
            var url = urls[0];
            debug ("got URL: %s, launching...", url);
            Utils.show_own_notification ("Launching shared URL",
                                         dev.device_name);
            try {
                AppInfo.launch_default_for_uri (url, null);
            } catch (Error e) {
                warning ("cannot launch application: %s", e.message);
            }
        }
    }

    private void handle_text (Device dev, Packet pkt) {
        var text = pkt.body.get_string_member ("text");
        debug ("shared text '%s'", text);
        var display = Gdk.Display.get_default ();
        if (display != null) {
            var cb = Gtk.Clipboard.get_default (display);
            cb.set_text (text, -1);
            Utils.show_own_notification ("Text copied to clipboard",
                                         dev.device_name);
        }
    }

    private Packet make_share_packet (string name, string data) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name (name);
        builder.add_string_value (data);
        builder.end_object ();
        return new Packet (SHARE,
                           builder.get_root ().get_object ());
    }

    private Packet make_file_share_packet (string filename, uint64 size,
                                           uint16 port) {

        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("filename");
        builder.add_string_value (filename);
        builder.end_object ();

        var pkt = new Packet (SHARE,
                              builder.get_root ().get_object ());
        pkt.payload = Packet.Payload () {
            size = size,
            port = port
        };
        return pkt;
    }

    public void share_url (Device dev, string url) {
        debug ("share url %s to device %s", url, dev.to_string ());

        dev.send (make_share_packet ("url", url));
    }

    public void share_text (Device dev, string text) {
        debug ("share text %s to device %s", text, dev.to_string ());

        dev.send (make_share_packet ("text", text));
    }

    public void share_file (Device dev, string path) throws Error {
        debug ("share file %s to device %s", path, dev.to_string ());

        var file = File.new_for_path (path);
        uint64 size = 0;
        try {
            var fi = file.query_info (FileAttribute.STANDARD_SIZE,
                                      FileQueryInfoFlags.NONE);
            size = fi.get_size ();
        } catch (Error e) {
            warning ("failed to obtain file size: %s", e.message);
            return;
        }

        debug ("file size: %llu", size);

        if (size == 0) {
            warning ("trying to share empty file %s", path);
            return;
        }

        FileInputStream input;
        try {
            input = file.read ();
        } catch (Error e) {
            warning ("failed to open source file at path %s: %s",
                     file.get_path (), e.message);
            throw e;
        }

        uint16 port;
        var listener = Core.instance ().transfer_manager.make_listener (out port);
        if (listener == null) {
            warning ("coult not allodate a listener");
            return;
        }
        debug ("allocated listener on port %u", port);

        var t = new UploadTransfer (dev, listener, input, size);

        Core.instance ().transfer_manager.push_job (t);

        t.start_async.begin ();
        dev.send (make_file_share_packet (file.get_basename (), size, port));
    }
}
