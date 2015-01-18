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

mconn-crypt.gi: src/mconn-crypt.h
	rm -f $@
	$(GEN_INTROSPECT) -n MConn \
		$< $(filter -I%,$(MCONNECT_CFLAGS)) > $@

mconn-crypt.vapi: mconn-crypt.gi
	rm -f $@
	vapigen --library mconn-crypt $<

# configure will expand bindir to ${exec_prefix}/bin, we want the
# whole thing, that's why mconnect.desktop is generated here and not
# in configure
do_desktop_subst = sed -e 's,[@]bindir[@],${bindir},g'
mconnect.desktop: mconnect.desktop.in
	$(do_desktop_subst) < $< > $@

git-source-dist:
	gitsha=`git rev-list HEAD -1`; \
	git archive --prefix=mconnect-$${gitsha}/ HEAD | \
		gzip -c > mconnect-$${gitsha}.tar.gz

BUILT_SOURCES = mconn-crypt.vapi mconn-crypt.gi mconnect.desktop

CLEANFILES = $(BUILT_SOURCES)

