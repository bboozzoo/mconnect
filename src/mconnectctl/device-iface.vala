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
namespace Mconnect {

    [DBus (name = "org.mconnect.Device")]
    public interface DeviceIface : Object {

        public abstract string id {
            owned get;
        }
        public abstract string name {
            owned get;
        }
        public abstract string device_type  {
            owned get;
        }
        public abstract uint protocol_version  {
            owned get;
        }
        public abstract string address  {
            owned get;
        }
        public abstract bool is_paired  {
            owned get;
        }
        public abstract bool allowed {
            owned get;
        }
        public abstract bool is_active {
            owned get;
        }
        public abstract bool is_connected {
            owned get;
        }
        public abstract string[] outgoing_capabilities {
            owned get;
        }
        public abstract string[] incoming_capabilities {
            owned get;
        }
        public abstract string certificate {
            owned get;
        }
    }
}