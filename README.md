# mconnect
mconnect - KDE Connect protocol implementation in Vala/C

GLib and Gio should be available even on trimmed down systems. Vala is
really needed only at build time. OpenSSL does the packet
encryption/decryption at the protocol level, while Json-glib does
packet parsing. Libnotify is responsible for displaying shell popups.

Since I'm new ot Vala, I'm treating this as a learning execrise, yet
with usable results.

# Building

Build dependencies (using package names as found in Fedora):

- vala
- vala-devel
- glib2-devel
- libgee-devel
- json-glib
- openssl-devel
- libnotify-devel

or see `mconnect.spec` in source tree. Once build deps are in place, run:

	autoreconf -if
    ./configure --prefix=<your favorite prefix>
    make
    make install
    # or make DESTDIR=<somedir> install if you want to inspect what
    # gets installed

# Configuration

A sample configuration file is provided in source tree, see
`mconnect.conf`. It will get installed to `${sysconfdir}/mconnect/`
(usually corresponding to `/etc/mconnect/`) by default. Once
`mconnect` starts it will pick the default file and make a copy of it
in user's config directory, specifically `~/.config/mconnect/`.

A device described in it's own group and listed in `main.devices`, has
to match exactly with incoming identity packets. However, since
`deviceId` is not known beforehand, neither shown in KDE Connect
Android application, only `name` and `type` are used for matching.

# Usage

Start it by running:

	mconnect -d

# Operation

The daemon starts listening on `0.0.0.0:1714` for incoming UDP
packets. Once an identity packet (a sort of a handshake) is received,
a connection at the sender's address will be made only if the device
is listed as `allowed` in `mconnect.conf` (see the sample config).
Should the device be whitelisted in configuration, pairing will happen
automatically.

