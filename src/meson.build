# make i18n works.
add_global_arguments('-DGETTEXT_PACKAGE="xdg-autostart"', language: 'c')

src = [ 
  'AutostartInfoBuilder.vala',
  'AutostartInfo.vala',
  'App.vala',
  'DirectoryReader.vala',
  'ProgramLauncher.vala' 
]

executable('xdg-autostart',
  src,
  config_data,
  dependencies: [glib, gobject],
  include_directories: config_dir,
  install: true
)
