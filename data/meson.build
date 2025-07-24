subdir('ui')
subdir('scss')
subdir('desktop')

# Install GSettings schema
install_data(
    'com.arkye.morghulis.gschema.xml',
    install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

project_resources += gnome.compile_resources(
    project_name,
    project_name + '.gresource.xml',
    dependencies: [blueprints, scss],
    source_dir: meson.current_build_dir(),
)