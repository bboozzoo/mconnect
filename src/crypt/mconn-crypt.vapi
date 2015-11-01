namespace Mconn {
	[CCode (cheader_filename = "mconn-crypt.h", type_id = "mconn_crypt_get_type ()")]
	public class Crypt : GLib.Object {
		[CCode (has_construct_function = false)]
		protected Crypt ();
		public GLib.ByteArray decrypt (GLib.Bytes data) throws GLib.Error;
		[CCode (has_construct_function = false)]
		public Crypt.for_key_path (string path);
		public string get_public_key_pem ();
		public unowned Mconn.Crypt @ref ();
		public void unref ();
	}
}
