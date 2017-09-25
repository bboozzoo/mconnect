project('mconnect', 'vala', 'c')

glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
gio_dep = dependency('gio-2.0')
gio_unix_dep = dependency('gio-unix-2.0')
json_glib_dep = dependency('json-glib-1.0')
gee_dep = dependency('gee-0.8')
libnotify_dep = dependency('libnotify')
gdk_dep = dependency('gdk-3.0')
atspi_dep = dependency('atspi-2')
gnutls_dep = dependency('gnutls')
posix_dep = meson.get_compiler('vala').find_library('posix')


add_project_arguments(['--vapidir',
                       join_paths(meson.current_source_dir(), 'vapi')],
                      language: 'vala')

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
	'src/mconnect/mousepad.vala',
	'src/mconnect/ping.vala',
	'src/mconnect/ping-proxy.vala',
	'src/mconnect/config.vala',
	'src/mconnect/application.vala',
	'src/mconnect/utils.vala',
	'src/mconnect/property-proxy.vala',
	'src/crypt/certificate.vala',
]

executable('mconnect', mconnect_src,
           dependencies : [glib_dep, gobject_dep,
                           gio_dep, gio_unix_dep,
                           json_glib_dep, gee_dep,
                           libnotify_dep, gdk_dep,
                           atspi_dep, gnutls_dep,
                           posix_dep])

mconnectctl_src = 'src/mconnectctl/main.vala'
executable('mconnectctl', mconnectctl_src,
           dependencies : [glib_dep, gobject_dep,
                           gio_dep, gio_unix_dep,
                           json_glib_dep, gee_dep,
                           libnotify_dep, gdk_dep,
                           atspi_dep, gnutls_dep])

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
