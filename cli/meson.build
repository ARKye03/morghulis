# Generate version configuration
version_conf = configuration_data()
version_conf.set('VERSION', meson.project_version())

version_vala = configure_file(
    input: 'version.vala.in',
    output: 'version.vala',
    configuration: version_conf,
)

executable(
    'morghulctl',
    ['cli.vala', version_vala],
    dependencies: [
        dependency('gio-unix-2.0'),
        dependency('gio-2.0'),
    ],
    c_args: '-w',
    install: true,
)