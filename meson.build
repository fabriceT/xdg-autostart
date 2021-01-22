project(
    'xdg-autostart', 
    'vala', 'c',
    version: '1.2.0'
)

add_project_arguments('-DGETTEXT_PACKAGE="xdg-autostart"', language: 'c')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0')
]

subdir('config')
subdir('src')

executable('xdg-autostart',
    sources_files,
    config_data,
    dependencies: dependencies,
    include_directories: config_dir,
    install: true
)
