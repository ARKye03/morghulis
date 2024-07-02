executable(
    project_name,
    project_resources,
    sources: ['main.vala', 'ui/NavBarWidget.vala'],
    vala_args: ['--gresourcesdir=data/'],
    dependencies: [
        dependency('gtk4'),
        dependency('gtk4-layer-shell-0'),
        dependency('astal-notifd-0.1'),
        dependency('astal-hyprland-0.1'),
        dependency('astal-mpris-0.1'),
        dependency('libpulse-simple'),
    ],
    install: true,
)