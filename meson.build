project('xdg-autostart', 'vala', 'c', version: '0.1.0')

glib = dependency('glib-2.0')
gobject = dependency('gobject-2.0')

conf = configuration_data()
conf.set_quoted('VERSION', '1.2.0')
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('LOCALEDIR', '.')
config_h = configure_file(output : 'config.h',
  configuration : conf)

# make i18n works.
add_global_arguments('-DGETTEXT_PACKAGE="xdg-autostart"', language: 'c')

executable('xdg-autostart',
  [ 'Config.vapi',
    'AutostartInfoBuilder.vala',
    'AutostartInfo.vala',
    'App.vala',
    'DirectoryReader.vala',
    'ProgramLauncher.vala' ],
  dependencies: [glib, gobject]
)
