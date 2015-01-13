using MConn;

void test_simple() {
	string file_path = "/tmp/test-key-vala.pem";
	FileUtils.remove(file_path);

	string pubkey1;
	string pubkey2;

	{
		assert(FileUtils.test(file_path, FileTest.EXISTS) == false);
		var c = new Crypt.for_key_path(file_path);
		assert(FileUtils.test(file_path, FileTest.EXISTS) == true);
		pubkey1 = c.get_public_key_pem();
		assert(pubkey1 != null);
	}

	// file should still exist
	assert(FileUtils.test(file_path, FileTest.EXISTS) == true);

	{
		assert(FileUtils.test(file_path, FileTest.EXISTS) == true);
		var c = new Crypt.for_key_path(file_path);
		assert(FileUtils.test(file_path, FileTest.EXISTS) == true);
		pubkey2 = c.get_public_key_pem();
		assert(pubkey2 != null);
	}

	debug("public key1:\n%s", pubkey1);
	debug("public key2:\n%s", pubkey2);
	assert(pubkey1 == pubkey2);
}

public static void main(string[] args) {
	Test.init(ref args);

	Test.add_func("/mconn-crypt-vala/simple", () => {
			test_simple();
		});
	Test.run();
}