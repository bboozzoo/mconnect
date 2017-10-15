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

using Gee;

[DBus (name = "org.mconnect.TransferManager")]
class TransferManagerDBusProxy : Object {

	private TransferManager manager;
	private DBusConnection bus;

	private int job_idx = 0;
	private const string DBUS_PATH = "/org/mconnect/transfer";

	private HashMap<string, TransferDBusProxy> jobs;

	public TransferManagerDBusProxy.with_manager(DBusConnection conn,
												 TransferManager manager) {
		this.jobs = new HashMap<string, TransferDBusProxy>();
		this.bus = conn;

		manager.new_transfer.connect(this.handle_new_transfer);
	}

	[DBus (visible = false)]
	public void publish() throws IOError {
		assert(this.bus != null);

		this.bus.register_object(DBUS_PATH, this);
	}

	/**
	 * list_jobs:
	 *
	 * Returns a list of DBus paths of all known transfer jobs
	 */
	public ObjectPath[] list_jobs() {
		ObjectPath[] jobs = {};

		foreach (var path in this.jobs.keys) {
			jobs += new ObjectPath(path);
		}
		return jobs;
	}


	private void handle_new_transfer(Object? mgr, TransferInterface job) {
		var path = make_transfer_path();
		var tproxy = new TransferDBusProxy.for_transfer_with_path(job,
																  new ObjectPath(path));

		this.jobs.@set(path, tproxy);
		tproxy.bus_register(this.bus);
		job.started.connect((_) => {
				this.transfer_started(path);
			});
		job.finished.connect((o) => {
				this.handle_transfer_done(path);
			});
		job.error.connect((o, err) => {
				this.handle_transfer_failed(path, err);
			});
	}

	private string make_transfer_path() {
		var path =  "/org/mconnect/transfer/%d".printf(this.job_idx);

		// bump jobs index
		this.job_idx++;

		return path;
	}

	private void handle_transfer_done(string path) {
		// var jp = this.find_proxy_for_job(TransferInterface(obj));
		var jp = this.jobs.@get(path);
		assert(jp != null);
		jp.bus_unregister(this.bus);

		this.transfer_finished(path);
	}

	private void handle_transfer_failed(string path, string err) {
		// var jp = this.find_proxy_for_job(TransferInterface(obj));
		var jp = this.jobs.@get(path);
		assert(jp != null);
		jp.bus_unregister(this.bus);

		this.transfer_failed(path, err);
	}

	public signal void transfer_finished(string path);

	public signal void transfer_failed(string path, string reason);

	public signal void transfer_started(string path);
}
