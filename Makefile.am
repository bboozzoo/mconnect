# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# AUTHORS
# Maciek Borzecki <maciek.borzecki (at] gmail.com>
#

# location of *.desktop file, usually /usr/share/applications
applicationsdir = $(datadir)/applications

applications_DATA = mconnect.desktop

mconnectdatadir = $(sysconfdir)/mconnect

mconnectdata_DATA = mconnect.conf

bin_PROGRAMS = mconnect

noinst_PROGRAMS = test-mconn-crypt \
		  test-mconn-crypt-vala

mconnect_SOURCES = src/main.vala \
		   src/discovery.vala \
		   src/packet.vala \
		   src/device.vala \
		   src/devicemanager.vala \
		   src/devicechannel.vala \
		   src/core.vala \
		   src/packethandlerinterface.vala \
		   src/packethandlers.vala \
		   src/notification.vala \
		   src/battery.vala \
		   src/telephony.vala \
		   src/config.vala \
		   src/mconn-crypt.c \
		   src/mconn-crypt.h

mconnect_LDADD = $(MCONNECT_LIBS)
mconnect_CFLAGS = $(MCONNECT_CFLAGS) -Isrc

noinst_LTLIBRARIES = libmconn-crypt.la
libmconn_crypt_la_SOURCES = src/mconn-crypt.c \
			    src/mconn-crypt.h
libmconn_crypt_la_CFLAGS = $(MCONNECT_CFLAGS)
libmconn_crypt_la_LIBADD = $(MCONNECT_LIBS)

test_mconn_crypt_SOURCES = test/mconn-crypt-test.c
test_mconn_crypt_LDADD = $(MCONNECT_LIBS) libmconn-crypt.la
test_mconn_crypt_CFLAGS = $(MCONNECT_CFLAGS) -Isrc

test_mconn_crypt_vala_SOURCES = test/mconn-crypt-vala-test.vala
test_mconn_crypt_vala_LDADD = $(MCONNECT_LIBS) libmconn-crypt.la
test_mconn_crypt_vala_CFLAGS = $(MCONNECT_CFLAGS) -Isrc -I.

VALAFLAGS = $(MCONNECT_VALAFLAGS) --vapidir=. --pkg=mconn-crypt

mconn-crypt.gir: libmconn-crypt.la
	rm -f $@
	$(G_IR_SCANNER) src/mconn-crypt.[ch] $(MCONNECT_CFLAGS) \
			--include=GObject-2.0 \
			--namespace=MConn --library $< \
			--output=$@

mconn-crypt.vapi: mconn-crypt.gir
	rm -f $@
	$(VALA_API_GEN) --library mconn-crypt $<

# configure will expand bindir to ${exec_prefix}/bin, we want the
# whole thing, that's why mconnect.desktop is generated here and not
# in configure
do_desktop_subst = sed -e 's,[@]bindir[@],${bindir},g'
mconnect.desktop: mconnect.desktop.in
	$(do_desktop_subst) < $< > $@

REV ?= HEAD

git-source-dist:
	gitsha=`git rev-list $(REV) -1`; \
	git archive --prefix=mconnect-$${gitsha}/ $(REV) | \
		gzip -c > mconnect-$${gitsha}.tar.gz

BUILT_SOURCES = mconn-crypt.vapi mconn-crypt.gir mconnect.desktop

CLEANFILES = $(BUILT_SOURCES)

