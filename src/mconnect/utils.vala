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
using Posix;

/**
 * @array_list_to_list:
 * @al: Gee.ArrayList<T>
 *
 * Convert Gee.ArrayList<T> to T[]
 */
T[] array_list_to_list<T>(Gee.ArrayList<T> al) {
	T[] out_list = new T[al.size];
	int i = 0;
	foreach(var v in al) {
		out_list[i] = v;
		i++;
	}
	return out_list;
}

namespace DebugLog{
	public bool Verbose = false;
}

void enable_vdebug() {
	DebugLog.Verbose = true;
}

/**
 * vdebug:
 * @format: format string
 *
 * Same as debug() but looks at verbose debug flag
 */
void vdebug(string format, ...) {
	if (DebugLog.Verbose == true) {
		var l = va_list();
		logv(null, LogLevelFlags.LEVEL_DEBUG, format, l);
	}
}

/**
 * make_unique_device_string:
 * @id: device ID
 * @name: device name
 * @type: device type
 * @pv: protocol version
 *
 * Generate device string that can be used as map index
 */
string make_unique_device_string(string id, string name,
								 string type, uint pv) {
	return make_device_string(id, name, type, pv).replace(" ", "-");
}

/**
 * make_device_string:
 * @id: device ID
 * @name: device name
 * @type: device type
 * @pv: protocol version
 *
 * Generate device string
 */
string make_device_string(string id, string name,
						  string type, uint pv) {
	return "%s-%s-%s-%u".printf(id, name, type, pv);

}

/**
 * socket_set_keepalive:
 * @sock: socket
 *
 * Set keepalive counters on socket
 */
void socket_set_keepalive(Socket sock) {
#if 0
	IPPROTO_TCP = 6,	   /* Transmission Control Protocol.  */

	TCP_KEEPIDLE	 4  /* Start keeplives after this period */
	TCP_KEEPINTVL	 5  /* Interval between keepalives */
	TCP_KEEPCNT		 6  /* Number of keepalives before death */
#endif
#if 0
	int option = 10;
	Posix.setsockopt(sock.fd, 6, 4, &option, (Posix.socklen_t) sizeof(int));
	option = 5;
	Posix.setsockopt(sock.fd, 6, 5, &option, (Posix.socklen_t) sizeof(int));
	option = 3;
	Posix.setsockopt(sock.fd, 6, 6, &option, (Posix.socklen_t) sizeof(int));
#endif

	int option = 10;
	Posix.setsockopt(sock.fd, IPProto.TCP,
					 Posix.TCP_KEEPIDLE,
					 &option, (Posix.socklen_t) sizeof(int));
	option = 5;
	Posix.setsockopt(sock.fd, IPProto.TCP,
					 Posix.TCP_KEEPINTVL,
					 &option, (Posix.socklen_t) sizeof(int));
	option = 3;
	Posix.setsockopt(sock.fd, IPProto.TCP,
					 Posix.TCP_KEEPCNT,
					 &option, (Posix.socklen_t) sizeof(int));

	// enable keepalive
	sock.set_keepalive(true);
}
