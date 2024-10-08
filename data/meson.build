subdir('scss')

targets = files('ui/StatusBar.blp')

blueprints = custom_target(
    'blueprints',
    input: targets,
    output: '.',
    command: [
        find_program('blueprint-compiler'),
        'batch-compile',
        '@OUTPUT@',
        '@CURRENT_SOURCE_DIR@',
        '@INPUT@',
    ],
)

project_resources = gnome.compile_resources(
    project_name + '-resources',
    project_name + '.gresource.xml',
    dependencies: [blueprints, scss],
)