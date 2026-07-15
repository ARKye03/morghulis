# Generate version configuration
version_conf = configuration_data()
version_conf.set('VERSION', meson.project_version())

version_vala = configure_file(
    input: 'version.vala.in',
    output: 'version.vala',
    configuration: version_conf,
)

project_resources += [
    version_vala,
    files(
        'Application.vala',
        'CircularProgress.vala',
        'CubicBezier.vala',
        'CssManager.vala',
        'MorghulProgressBar.vala',
        'ScrollableIndicatorMenu.vala',
        'Gizmo.vala',
        'Options.vala',
        'Window.vala',
    ),
]