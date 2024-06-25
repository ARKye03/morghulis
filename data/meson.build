blueprints = custom_target(
    'blueprints',
    input: files(
        'ui/NavBar.blp',
    ),
    output: '.',
    command: [
        find_program('blueprint-compiler'),
        'batch-compile',
        '@OUTPUT@',
        '@CURRENT_SOURCE_DIR@',
        '@INPUT@',
    ],
)

asresources = gnome.compile_resources(
    'as-resources',
    'ui/NavBar.blp',
    source_dir: 'data',
    c_name: 'as',
    dependencies: blueprints,
)