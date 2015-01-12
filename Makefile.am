bin_PROGRAMS = mconnect

noinst_PROGRAMS = test-mconn-crypt

mconnect_SOURCES = src/main.vala \
		   src/discovery.vala \
		   src/packet.vala \
		   src/device.vala \
		   src/devicemanager.vala

mconnect_LDADD = $(MCONNECT_LIBS)

mconnect_CFLAGS = $(MCONNECT_CFLAGS)

test_mconn_crypt_SOURCES = src/mconn-crypt-test.c \
			   src/mconn-crypt.c \
			   src/mconn-crypt.h

test_mconn_crypt_LDADD = $(MCONNECT_LIBS)
test_mconn_crypt_CFLAGS = $(MCONNECT_CFLAGS)

VALAFLAGS = $(MCONNECT_VALAFLAGS)

