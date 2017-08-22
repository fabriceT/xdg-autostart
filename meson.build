project('xdg-autostart', 'vala', 'c', version: '0.1.0')

glib = dependency('glib-2.0')
gobject = dependency('gobject-2.0')

executable('xdg-autostart',
  [ 'AutostartInfoBuilder.vala',
    'AutostartInfo.vala',
    'App.vala',
    'DirectoryReader.vala',
    'ProgramLauncher.vala'],
  dependencies: [glib, gobject]
)
