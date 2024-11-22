sass = find_program('sass')

scss_deps = files(
    '_Colors.scss',
    '_Mpris.scss',
    '_OnScreenDisplay.scss',
    '_Runner.scss',
    '_SideDashboard.scss',
    '_NavBar.scss',
    '_adw.scss',
    '_Notif.scss',
    'main.scss',
)

scss = custom_target(
    'scss',
    input: 'main.scss',
    output: 'morghulis.css',
    command: [
        sass,
        '@INPUT@',
        '@OUTPUT@',
    ],
    depend_files: scss_deps,
)