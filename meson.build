
project(
  'morghulis',
  ['vala', 'c'],
  version: run_command('cat', 'version').stdout().strip(),
  meson_version: '>= 1.4.0',
)

gnome = import('gnome')
i18n = import('i18n')

i18n.gettext('morghulis', preset: 'glib')

project_name = meson.project_name()
project_resources = []

subdir('lib')
subdir('data')
subdir('src')

gnome.post_install(
  glib_compile_schemas: true,
  # Disabled: this project ships no hicolor icons (assets go through gresource),
  # so /usr/local/share/icons/hicolor never exists and gtk4-update-icon-cache fails.
  # gtk_update_icon_cache: true,
  update_desktop_database: true,
)
