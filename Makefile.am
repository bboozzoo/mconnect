bin_PROGRAMS = mconnect

noinst_PROGRAMS = test-mconn-crypt \
		  test-mconn-crypt-vala

mconnect_SOURCES = src/main.vala \
		   src/discovery.vala \
		   src/packet.vala \
		   src/device.vala \
		   src/core.vala \
		   src/mconn-crypt.c \
		   src/mconn-crypt.h

mconnect_LDADD = $(MCONNECT_LIBS)

mconnect_CFLAGS = $(MCONNECT_CFLAGS) -Isrc

test_mconn_crypt_SOURCES = test/mconn-crypt-test.c \
			   src/mconn-crypt.c \
			   src/mconn-crypt.h

test_mconn_crypt_LDADD = $(MCONNECT_LIBS)
test_mconn_crypt_CFLAGS = $(MCONNECT_CFLAGS) -Isrc

test_mconn_crypt_vala_SOURCES = test/mconn-crypt-vala-test.vala \
				src/mconn-crypt.c \
				src/mconn-crypt.h
test_mconn_crypt_vala_LDADD = $(MCONNECT_LIBS)
test_mconn_crypt_vala_CFLAGS = $(MCONNECT_CFLAGS) -Isrc -I.

VALAFLAGS = $(MCONNECT_VALAFLAGS) --vapidir=. --pkg=mconn-crypt

mconn-crypt.gir: src/mconn-crypt.h
	rm -f $@
	g-ir-scanner --header-only -n MConn --symbol-prefix mconn \
		$< $(filter -I%,$(MCONNECT_CFLAGS)) | \
		grep -v warning: > $@

mconn-crypt.vapi: mconn-crypt.gir
	rm -f $@
	vapigen --library mconn-crypt $<


BUILT_SOURCES = mconn-crypt.vapi mconn-crypt.gir

CLEANFILES = $(BUILT_SOURCES)

