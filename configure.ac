#
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
AC_PREREQ(2.61)
AC_INIT([mconnect], [0.1.0], [maciek.borzecki@gmail.com])
AC_CONFIG_SRCDIR([src/main.vala])
AC_CONFIG_AUX_DIR([.])
AC_PROG_MAKE_SET
AM_INIT_AUTOMAKE([tar-pax foreign subdir-objects])
AM_SILENT_RULES([yes])

AM_MAINTAINER_MODE

# Checks for header files.
# AC_HEADER_STDC
# AC_CHECK_HEADERS([stdlib.h])

# Checks for typedefs, structures, and compiler characteristics.
# AC_C_CONST

# Checks for programs.
AC_PROG_CC
AM_PROG_VALAC([0.7.0])
AC_PROG_INSTALL

AC_SUBST(MCONNECT_VALAFLAGS, ["--pkg=json-glib-1.0 --pkg=gee-0.8 --pkg=libnotify"])
# AC_SUBST(MCONNECT_VALAFLAGS, [--pkg=json-glib-1.0 --pkg=gee-0.8])
PKG_CHECK_MODULES(MCONNECT, [glib-2.0,
                             gobject-2.0,
                             gio-2.0,
                             gio-unix-2.0,
                             json-glib-1.0,
                             gee-0.8,
                             libcrypto
                             libvala-0.26
                             libnotify
                             ])
AC_SUBST(MCONNECT_CFLAGS)
AC_SUBST(MCONNECT_LIBS)

AC_SUBST(GEN_INTROSPECT,$($PKG_CONFIG --variable=gen_introspect libvala-0.26))

# Files to generate
AC_CONFIG_FILES([Makefile])

# Output
AC_OUTPUT
