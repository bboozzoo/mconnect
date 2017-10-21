using Mconn;

void test_generate () {
    string key_path = "/tmp/test-key-vala.pem";
    string cert_path = "/tmp/test-cert-vala.pem";
    FileUtils.remove (key_path);
    FileUtils.remove (cert_path);

    assert (FileUtils.test (key_path, FileTest.EXISTS) == false);
    try {
        Crypt.generate_key_cert (key_path, cert_path, "foo");
    } catch (Error e) {
        warning ("generate failed: %s", e.message);
        Test.fail ();
    }
    assert (FileUtils.test (key_path, FileTest.EXISTS) == true);
    assert (FileUtils.test (cert_path, FileTest.EXISTS) == true);
}

void test_generate_load () {
    string key_path = "/tmp/test-key-vala.pem";
    string cert_path = "/tmp/test-cert-vala.pem";
    FileUtils.remove (key_path);
    FileUtils.remove (cert_path);

    try {
        Crypt.generate_key_cert (key_path, cert_path, "bar");
    } catch (Error e) {
        warning ("generate failed: %s", e.message);
        Test.fail ();
    }

    try {
        var cert = new TlsCertificate.from_files (cert_path,
                                                  key_path);
    } catch (Error e) {
        warning ("load from files failed: %s", e.message);
        Test.fail ();
    }
}

void test_custom_cn () {
    string key_path = "/tmp/test-key-vala.pem";
    string cert_path = "/tmp/test-cert-vala.pem";
    FileUtils.remove (key_path);
    FileUtils.remove (cert_path);

    try {
        Crypt.generate_key_cert (key_path, cert_path, "custom-cn");
    } catch (Error e) {
        warning ("generate failed: %s", e.message);
        Test.fail ();
    }

    uint8[] data;
    try {
        File.new_for_path (cert_path).load_contents (null, out data, null);
    } catch (Error e) {
        warning ("load contents failed: %s", e.message);
        Test.fail ();
    }

    var datum = GnuTLS.Datum () {
        data = data, size = data.length
    };

    var cert = GnuTLS.X509.Certificate.create ();
    var res = cert.import (ref datum, GnuTLS.X509.CertificateFormat.PEM);
    assert (res == GnuTLS.ErrorCode.SUCCESS);

    // verify DN
    var dn = new uint8[1024];
    size_t sz = dn.length;
    cert.get_dn (dn, ref sz);
    debug ("dn: %s\n", (string) dn);

    var issuer_dn = new uint8[1024];
    sz = issuer_dn.length;
    cert.get_issuer_dn (issuer_dn, ref sz);
    debug ("dn: %s\n", (string) issuer_dn);

    var subject = (string) dn;
    var issuer = (string) issuer_dn;

    // verify that the certificate is self signed
    assert (subject == issuer);
    //
    assert ("CN=custom-cn" in subject);
}

void test_fingerprint () {
    var pem = """-----BEGIN CERTIFICATE-----
MIIC8jCCAdoCAQowDQYJKoZIhvcNAQEFBQAwPzERMA8GA1UEChMIbWNvbm5lY3Qx
ETAPBgNVBAsTCG1jb25uZWN0MRcwFQYDVQQDDA5tYWNpZWtAY29yc2FpcjAeFw0x
NzA5MjQxOTU3NDVaFw0yNzA5MjQxOTU3NDVaMD8xETAPBgNVBAoTCG1jb25uZWN0
MREwDwYDVQQLEwhtY29ubmVjdDEXMBUGA1UEAwwObWFjaWVrQGNvcnNhaXIwggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDBWMM09dCCGXjY1aZ261nCa8+q
3ejDOHf21+Mt6yJnoWjPGvTK21MbRFPkeQe62FJHF3q8iXe3sSEdFk/f56G8ZZ4t
Qw/ST//kxtf/CKHPuoZeAFgQpYEKE3GVUX5M3b8+4YSKSRXs3FE4D5awQVdstI31
N53plyOLdJe5IeK1kESsT0UgVo2RTHCOByel9WB2zcalQVTl8UxGKJcgrSuXj2f2
1SBxHupOX0Ej7vTr+gIBNBRbwbVdsafEW/gRngyCWIO30cPKoaUSkoCppXQ+6hYd
/aOt+6/bBOISGJdy6uyM74jqoEbEMdhUXHfPFNCelIABxUMez0SNrRmdag2VAgMB
AAEwDQYJKoZIhvcNAQEFBQADggEBAEnJ+IsjGvBmlWAg5vlmWUY0OVMJa8Gl9ept
HWLIjK16XARAOwIcePNfDPyITWaxT5YV+MZotm1m6HkY5rPCeOjV7nzHrHjTjZqO
sCmsSGcb9ZkEQfRNGTmFFthkcnfTU9mKh8oGc/a9r0DDgYcPSCgqERt2fgiBrt85
85PVl16fCSObVwOu5u5TtrfWkHpEHbjBU9AX52+IOYg7RsM7I4OnH+5svhmWqAxW
/PXFBB3q2nX2XXqFRhqeN9eOlHBQ5EoZh8GUp7vJyxp5eAS9g2KVtCBwTDElQt4D
4hu+QuzzEmoWY9w1R+hblNu/37mWkzFFrLqYlkNU2vbKkuWMOTg=
-----END CERTIFICATE-----""";
    var expected = "eb2611a447085322b206fa61d4bc5869b4a55657";

    var fingerprint = Crypt.fingerprint_certificate (pem);
    // SHA1
    assert (fingerprint.length == 20);

    var sb = new StringBuilder.sized (20 * 2);
    foreach (var b in fingerprint) {
        sb.append_printf ("%02x", b);
    }

    assert (sb.str == expected);
}

public static void main (string[] args) {
    Test.init (ref args);

    Test.add_func ("/mconn-crypt-vala/generated", test_generate);
    Test.add_func ("/mconn-crypt-vala/load", test_generate_load);
    Test.add_func ("/mconn-crypt-vala/verify-cn", test_custom_cn);
    Test.add_func ("/mconn-crypt-vala/fingerprint", test_fingerprint);
    Test.run ();
}