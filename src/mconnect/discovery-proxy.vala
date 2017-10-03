/* ex:ts=4:sw=4:sts=4:et */
/* -*- tab-width: 4; c-basic-offset: 4; indent-tabs-mode: nil -*- */
/**
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 *
 * AUTHORS
 * Maciek Borzecki <maciek.borzecki (at] gmail.com>
 */

[DBus (name = "org.mconnect.Discovery")]
class DiscoveryDBusProxy : Object {

	private Discovery discovery;
	private const string DBUS_PATH = "/org/mconnect/discovery";
	private DBusConnection bus = null;

	public DiscoveryDBusProxy.with_discovery(DBusConnection bus,
											 Discovery discovery) {
		this.discovery = discovery;
		this.bus = bus;
	}

	[DBus (visible = false)]
	public void publish() throws IOError {
		assert(this.bus != null);

		this.bus.register_object(DBUS_PATH, this);

	}

	public void announce() {
		discovery.announce();
	}
}