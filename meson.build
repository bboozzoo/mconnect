project('mconnect', 'vala', 'c')

# dependencies
glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
gio_dep = dependency('gio-2.0')
gio_unix_dep = dependency('gio-unix-2.0')
json_glib_dep = dependency('json-glib-1.0')
gee_dep = dependency('gee-0.8')
libnotify_dep = dependency('libnotify')
gdk_dep = dependency('gdk-3.0')
gtk_dep = dependency('gtk+-3.0')
atspi_dep = dependency('atspi-2')
gnutls_dep = dependency('gnutls')
posix_dep = meson.get_compiler('vala').find_library('posix')


add_project_arguments(['--vapidir',
                       join_paths(meson.current_source_dir(), 'vapi')],
                      language: 'vala')

# binaries
mconnect_src = [
  'src/mconnect/main.vala',
	'src/mconnect/discovery.vala',
	'src/mconnect/packet.vala',
	'src/mconnect/device.vala',
	'src/mconnect/discovereddevice.vala',
	'src/mconnect/device-proxy.vala',
	'src/mconnect/devicemanager.vala',
	'src/mconnect/devicemanager-proxy.vala',
	'src/mconnect/devicechannel.vala',
	'src/mconnect/core.vala',
	'src/mconnect/packethandlerinterface.vala',
	'src/mconnect/packethandlerinterface-proxy.vala',
	'src/mconnect/packethandlers.vala',
	'src/mconnect/packethandlers-proxy.vala',
	'src/mconnect/notification.vala',
	'src/mconnect/battery.vala',
	'src/mconnect/battery-proxy.vala',
	'src/mconnect/telephony.vala',
	'src/mconnect/telephony-proxy.vala',
	'src/mconnect/mousepad.vala',
	'src/mconnect/ping.vala',
	'src/mconnect/ping-proxy.vala',
	'src/mconnect/config.vala',
	'src/mconnect/application.vala',
	'src/mconnect/utils.vala',
	'src/mconnect/property-proxy.vala',
	'src/mconnect/share.vala',
	'src/mconnect/share-proxy.vala',
	'src/mconnect/mpris.vala',
	'src/mconnect/mpris-proxy.vala',
	'src/mconnect/io-job.vala',
	'src/mconnect/transfer-manager.vala',
	'src/mconnect/transfer-manager-proxy.vala',
	'src/mconnect/transfer-interface.vala',
	'src/mconnect/transfer-proxy.vala',
	'src/mconnect/transfer-download.vala',
	'src/mconnect/transfer-upload.vala',
	'src/mconnect/logging.vala',
	'src/crypt/certificate.vala',
]

mconnect_prog = executable('mconnect', mconnect_src,
                           dependencies : [glib_dep, gobject_dep,
                                           gio_dep, gio_unix_dep,
                                           json_glib_dep, gee_dep,
                                           libnotify_dep, gdk_dep,
                                           atspi_dep, gnutls_dep,
                                           posix_dep, gtk_dep],
                           install: true)

mconnectctl_src = [
  'src/mconnectctl/main.vala',
  'src/mconnectctl/device-manager-iface.vala',
  'src/mconnectctl/device-iface.vala',
  'src/mconnectctl/share-iface.vala',
  'src/mconnectctl/telephony-iface.vala',
]
executable('mconnectctl', mconnectctl_src,
           dependencies : [glib_dep, gobject_dep,
                           gio_dep, gio_unix_dep],
           install: true)

# tests
test_mconn_crypt_src = [
  'test/mconn-crypt-vala-test.vala',
  'src/crypt/certificate.vala',
]
test_mconn_crypt = executable('test-mconn-crypt', test_mconn_crypt_src,
                              dependencies: [
                                glib_dep, gobject_dep,
                                gio_dep, gio_unix_dep,
                                gnutls_dep, posix_dep,
                              ],
                              install: false)
test('mconn-crypt', test_mconn_crypt)

test_mconn_utils_src = [
  'test/mconn-utils-test.vala',
  'src/mconnect/utils.vala',
  'src/mconnect/logging.vala',
]
test_mconn_utils = executable('test-mconn-utils', test_mconn_utils_src,
                              dependencies: [
                                glib_dep, gobject_dep,
                                gio_dep, gio_unix_dep,
                                posix_dep, libnotify_dep,
                              ],
                              install: false)
test('mconn-utils', test_mconn_utils)

# other files
applicationsdir = join_paths(get_option('datadir'),
                             'applications')

conf = configuration_data()
conf.set('bindir',
         join_paths(get_option('prefix'), get_option('bindir')))

configure_file(output: 'mconnect.desktop',
               input: 'mconnect.desktop.in',
               configuration: conf,
               install_dir: applicationsdir)

mconnectdatadir = join_paths(get_option('datadir'),
                             'mconnect')
install_data('mconnect.conf',
             install_dir: mconnectdatadir,
             install_mode: 'rw-r--r--')

# other targets

gdb_conf = configuration_data()
gdb_conf.set('bindir', meson.build_root())
gdb_script = configure_file(output: 'gdb-script',
                            input: 'gdb-script.in',
                            configuration: gdb_conf)
run_target('run-gdb',
           command: ['gdb', '-x', join_paths(meson.build_root(), 'gdb-script')],
           depends: [mconnect_prog])
