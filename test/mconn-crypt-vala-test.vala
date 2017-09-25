using Mconn;

void test_generate() {
	string key_path = "/tmp/test-key-vala.pem";
	string cert_path = "/tmp/test-cert-vala.pem";
	FileUtils.remove(key_path);
	FileUtils.remove(cert_path);

	assert(FileUtils.test(key_path, FileTest.EXISTS) == false);
	try {
		Crypt.generate_key_cert(key_path, cert_path, "foo");
	} catch (Error e) {
		warning("generate failed: %s", e.message);
		Test.fail();
	}
	assert(FileUtils.test(key_path, FileTest.EXISTS) == true);
	assert(FileUtils.test(cert_path, FileTest.EXISTS) == true);
}

void test_generate_load() {
	string key_path = "/tmp/test-key-vala.pem";
	string cert_path = "/tmp/test-cert-vala.pem";
	FileUtils.remove(key_path);
	FileUtils.remove(cert_path);

	try {
		Crypt.generate_key_cert(key_path, cert_path, "bar");
	} catch (Error e) {
		warning("generate failed: %s", e.message);
		Test.fail();
	}

	try {
		var cert = new TlsCertificate.from_files(cert_path,
												 key_path);
	} catch (Error e) {
		warning("load from files failed: %s", e.message);
		Test.fail();
	}
}

void test_custom_cn() {
	string key_path = "/tmp/test-key-vala.pem";
	string cert_path = "/tmp/test-cert-vala.pem";
	FileUtils.remove(key_path);
	FileUtils.remove(cert_path);

	try {
		Crypt.generate_key_cert(key_path, cert_path, "custom-cn");
	} catch (Error e) {
		warning("generate failed: %s", e.message);
		Test.fail();
	}

	uint8[] data;
	try {
		File.new_for_path(cert_path).load_contents(null, out data, null);
	} catch (Error e) {
		warning("load contents failed: %s", e.message);
		Test.fail();
	}

	var datum = GnuTLS.Datum() { data=data, size=data.length };

	var cert = GnuTLS.X509.Certificate.create();
	var res = cert.import(ref datum, GnuTLS.X509.CertificateFormat.PEM);
	assert(res == GnuTLS.ErrorCode.SUCCESS);

	// verify DN
	var dn = new uint8[1024];
	size_t sz = dn.length;
	cert.get_dn(dn, ref sz);
	debug("dn: %s\n", (string)dn);

	var issuer_dn = new uint8[1024];
	sz = issuer_dn.length;
	cert.get_issuer_dn(issuer_dn, ref sz);
	debug("dn: %s\n", (string)issuer_dn);

	var subject = (string)dn;
	var issuer = (string)issuer_dn;

	// verify that the certificate is self signed
	assert(subject == issuer);
	//
	assert("CN=custom-cn" in subject);
}

public static void main(string[] args) {
	Test.init(ref args);

	Test.add_func("/mconn-crypt-vala/generated", test_generate);
	Test.add_func("/mconn-crypt-vala/load", test_generate_load);
	Test.add_func("/mconn-crypt-vala/verify-cn", test_custom_cn);
	Test.run();
}