project(
  'paper-plane',
  'rust',
  version: '0.1.0-beta.5',
  meson_version: '>= 0.59',
)

i18n = import('i18n')
gnome = import('gnome')

base_id = 'app.drey.PaperPlane'

dependency('glib-2.0', version: '>= 2.72')
dependency('gio-2.0', version: '>= 2.72')
dependency('gtk4', version: '>= 4.12')
dependency('libadwaita-1', version: '>= 1.4')
dependency('shumate-1.0', version: '>= 1')
dependency('tdjson', version: '>= 1.8.19')

glib_compile_resources = find_program('glib-compile-resources', required: true)
glib_compile_schemas = find_program('glib-compile-schemas', required: true)
desktop_file_validate = find_program('desktop-file-validate', required: false)
appstream_util = find_program('appstream-util', required: false)
cargo = find_program('cargo', required: true)

version = meson.project_version()

prefix = get_option('prefix')
bindir = prefix / get_option('bindir')
localedir = prefix / get_option('localedir')

datadir = prefix / get_option('datadir')
pkgdatadir = datadir / meson.project_name()
iconsdir = datadir / 'icons'
podir = meson.project_source_root() / 'po'
gettext_package = meson.project_name()

tg_api_id = get_option('tg_api_id')
tg_api_hash = get_option('tg_api_hash')

if get_option('profile') == 'development'
  profile = 'Devel'
  vcs_tag = 'r' \
    + run_command('git', 'rev-list', '--count', 'HEAD').stdout().strip() \
    + '.' \
    + run_command('git', 'rev-parse', '--short', 'HEAD').stdout().strip()
  if vcs_tag == ''
    version_suffix = '-devel'
  else
    version_suffix = '-@0@'.format(vcs_tag)
  endif
  application_id = '@0@.@1@'.format(base_id, profile)
else
  profile = ''
  version_suffix = ''
  application_id = base_id
endif

subdir('data')
subdir('po')
subdir('src')

gnome.post_install(
  gtk_update_icon_cache: true,
  glib_compile_schemas: true,
  update_desktop_database: true,
)
