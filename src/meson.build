executable(
    project_name,
    project_resources,
    sources: ['main.vala', 'ui/NavBarWidget.vala'],
    vala_args: ['--gresourcesdir=data/'],
    dependencies: [
        dependency('gtk4'),
        dependency('gtk4-layer-shell-0'),
        dependency('astal-wireplumber-0.1'),
        # dependency('astal-0.1'),
        # dependency('astal-network-0.1'),
        # dependency('astal-tray-0.1'),
        dependency('astal-mpris-0.1'),
        dependency('astal-hyprland-0.1'),
    ],
    install: true,
)