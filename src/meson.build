source_files = [
    'App.vala',
    'Daemon.vala',
    'StatusBar.vala',
    'Mpris.vala',
    'Utils/Layer.vala',
]

executable(
    project_name,
    project_resources,
    sources: source_files,
    vala_args: ['--gresourcesdir=data/'],
    dependencies: [
        dependency('gtk4'),
        dependency('gtk4-layer-shell-0'),
        dependency('astal-wireplumber-0.1'),
        dependency('astal-mpris-0.1'),
        dependency('astal-hyprland-0.1'),
        dependency('gio-unix-2.0'),
        dependency('libadwaita-1'),
    ],
    link_args: ['-lm'],
    install: true,
)