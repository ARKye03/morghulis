subdir('ui')
subdir('scss')
subdir('desktop')

project_resources += gnome.compile_resources(
    project_name,
    project_name + '.gresource.xml',
    dependencies: [blueprints, scss],
    source_dir: meson.current_build_dir(),
)