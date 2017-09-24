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

applications_DATA = \
	mconnect.desktop

mconnectdatadir = $(datadir)/mconnect

mconnectdata_DATA = \
	mconnect.conf

bin_PROGRAMS = \
	mconnect \
	mconnectctl

noinst_PROGRAMS = \
	test-mconn-crypt

noinst_LTLIBRARIES =

VALAFLAGS = \
	--no-color \
	-g \
	--vapidir=vapi \
	--pkg=gio-2.0 \
	--pkg=gio-unix-2.0 \
	--pkg=json-glib-1.0 \
	--pkg=gee-0.8 \
	--pkg=libnotify \
	--pkg=posix \
	--pkg=gdk-3.0 \
	--pkg=atspi-2 \
  --pkg=gnutls \
	--vapidir=src/crypt

TESTS = \
	test-mconn-crypt

#-------------------------------------------------------------

mconnect_SOURCES = \
	src/mconnect/main.vala \
	src/mconnect/discovery.vala \
	src/mconnect/packet.vala \
	src/mconnect/device.vala \
	src/mconnect/discovereddevice.vala \
	src/mconnect/device-proxy.vala \
	src/mconnect/devicemanager.vala \
	src/mconnect/devicemanager-proxy.vala \
	src/mconnect/devicechannel.vala \
	src/mconnect/core.vala \
	src/mconnect/packethandlerinterface.vala \
	src/mconnect/packethandlerinterface-proxy.vala \
	src/mconnect/packethandlers.vala \
	src/mconnect/packethandlers-proxy.vala \
	src/mconnect/notification.vala \
	src/mconnect/battery.vala \
	src/mconnect/battery-proxy.vala \
	src/mconnect/telephony.vala \
	src/mconnect/mousepad.vala \
	src/mconnect/ping.vala \
	src/mconnect/ping-proxy.vala \
	src/mconnect/config.vala \
	src/mconnect/application.vala \
	src/mconnect/utils.vala \
	src/mconnect/property-proxy.vala \
	src/crypt/certificate.vala

mconnect_LDADD = \
	$(MCONNECT_LIBS)

mconnect_CFLAGS = \
	$(MCONNECT_CFLAGS) \
	-I$(top_srcdir)/src/crypt

#-------------------------------------------------------------

test_mconn_crypt_SOURCES = \
	src/crypt/certificate.vala \
	test/mconn-crypt-vala-test.vala

test_mconn_crypt_LDADD = \
	$(MCONNECT_LIBS)

test_mconn_crypt_CFLAGS = \
	$(MCONNECT_CFLAGS)

test_mconn_crypt_VALAFLAGS = \
	--pkg=gio-2.0 \
	--pkg=posix \
	--pkg=gnutls

#-------------------------------------------------------------

mconnectctl_SOURCES = \
	src/mconnectctl/main.vala

mconnectctl_LDADD = \
	$(MCONNECT_LIBS)

mconnectctl_CFLAGS = \
	$(MCONNECT_CFLAGS)


#-------------------------------------------------------------

# configure will expand bindir to ${exec_prefix}/bin, we want the
# whole thing, that's why mconnect.desktop is generated here and not
# in configure
do_desktop_subst = sed -e 's,[@]bindir[@],${bindir},g'
mconnect.desktop: mconnect.desktop.in
	$(do_desktop_subst) < $< > $@

#-------------------------------------------------------------

REV ?= HEAD

git-source-dist:
	gitsha=`git rev-list $(REV) -1`; \
	git archive --prefix=mconnect-$${gitsha}/ $(REV) | \
		gzip -c > mconnect-$${gitsha}.tar.gz

#-------------------------------------------------------------

run-gdb: gdb-script install
	gdb -x gdb-script

.PHONY: run-gdb

gdb-script: gdb-script.in
	sed -e 's,[@]bindir[@],${bindir},g' < $< > $@

#-------------------------------------------------------------

GEN_FROM_VALA = $(filter %.vala,$(mconnect_SOURCES) $(test_mconn_crypt_SOURCES))
BUILT_SOURCES = \
	mconnect.desktop \
	$(GEN_FROM_VALA:.vala=.c)

CLEANFILES = $(BUILT_SOURCES)
