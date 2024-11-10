project_resources += [
    'Main.vala',
    'App.vala',
    'StatusBar.vala',
    'QuickSettings.vala',
    'QuickSettingsButton.vala',
    'Runner.vala',
    'RunnerButton.vala',
    'Mpris.vala',
    'OnScreenDisplay.vala',
    'ImageFrame.vala',
    'Utils/Layer.vala',
]

executable(
    project_name,
    project_resources,
    vala_args: ['--gresourcesdir=data/'],
    dependencies: [
        dependency('gtk4'),
        dependency('gtk4-layer-shell-0'),
        dependency('libnm'),
        dependency('astal-wireplumber-0.1'),
        dependency('astal-mpris-0.1'),
        dependency('astal-hyprland-0.1'),
        dependency('astal-io-0.1'),
        # dependency('astal-tray-0.1'),
        dependency('astal-notifd-0.1'),
        dependency('astal-network-0.1'),
        dependency('astal-bluetooth-0.1'),
        dependency('astal-apps-0.1'),
        dependency('gio-unix-2.0'),
        dependency('libadwaita-1'),
    ],
    link_args: ['-lm'], # Link math library
    install: true,
)