bin_PROGRAMS = mconnect

noinst_PROGRAMS = test-mconn-crypt \
		  test-mconn-crypt-vala

mconnect_SOURCES = src/main.vala \
		   src/discovery.vala \
		   src/packet.vala \
		   src/device.vala \
		   src/devicemanager.vala

mconnect_LDADD = $(MCONNECT_LIBS)

mconnect_CFLAGS = $(MCONNECT_CFLAGS)

test_mconn_crypt_SOURCES = test/mconn-crypt-test.c \
			   src/mconn-crypt.c \
			   src/mconn-crypt.h

test_mconn_crypt_LDADD = $(MCONNECT_LIBS)
test_mconn_crypt_CFLAGS = $(MCONNECT_CFLAGS) -Isrc

test_mconn_crypt_vala_SOURCES = test/mconn-crypt-vala-test.vala \
				src/mconn-crypt.c \
				src/mconn-crypt.h
test_mconn_crypt_vala_LDADD = $(MCONNECT_LIBS)
test_mconn_crypt_vala_CFLAGS = $(MCONNECT_CFLAGS) -Isrc

VALAFLAGS = $(MCONNECT_VALAFLAGS) --vapidir=src --pkg=mconn-crypt

