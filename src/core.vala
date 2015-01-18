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
using MConn;

class Core : Object {

	public Crypt crypt { get; private set; default = null; }

	public PacketHandlers handlers {get; private set; default = null; }

	private static Core _instance = null;

	private Core() {
		debug("init core");
	}

	public static Core? instance() {
		if (Core._instance == null)
		{
			var crypt = new Crypt.for_key_path("private.pem");

			var core = new Core();
			var handlers = new PacketHandlers();
			core.crypt = crypt;
			core.handlers = handlers;

			info("supported interfaces: %s", string.joinv(", ",
														  handlers.interfaces));
			Core._instance = core;
		}

		return Core._instance;
	}

}