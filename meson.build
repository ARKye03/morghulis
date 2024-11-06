project(
  'morghulis',
  ['vala', 'c'],
  version: '0.1',
  meson_version: '>= 1.4.0',
)

gnome = import('gnome')
i18n = import('i18n')

i18n.gettext('morghulis', preset: 'glib')

project_name = meson.project_name()
project_resources = []

subdir('data')
subdir('src')

gnome.post_install(
  glib_compile_schemas: true,
  gtk_update_icon_cache: true,
  update_desktop_database: true,
)
