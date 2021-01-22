conf = configuration_data()
conf.set_quoted('VERSION', meson.project_version())
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('LOCALEDIR', '.')

configure_file(
	output : 'config.h', 
	configuration : conf
)

config_dir = include_directories('.')

config_data = files(
	'Config.vapi',
)
