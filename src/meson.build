subdir('Modules')
subdir('Tray')
subdir('NavBar')
subdir('Notifications')
subdir('OnScreenDisplay')
subdir('QuickMenu')
subdir('Runner')

project_resources += ['Main.vala', 'App.vala']

vapidir = meson.current_source_dir() + '/vapi/'

executable(
    project_name,
    project_resources,
    vala_args: [
        '--gresourcesdir=data/',
        '--vapidir=' + vapidir,
    ],

    dependencies: [
        dependency('gtk4'),
        dependency('gtk4-layer-shell-0'),
        dependency('astal-4-4.0'),
        dependency('astal-io-0.1'),
        dependency('libnm'),
        dependency('astal-hyprland-0.1', required: false),
        dependency('astal-river-0.1', required: false),
        dependency('astal-wireplumber-0.1'),
        dependency('astal-mpris-0.1'),
        dependency('astal-battery-0.1', required: false),
        dependency('astal-power-profiles-0.1', required: false),
        dependency('astal-tray-0.1'),
        dependency('astal-notifd-0.1'),
        dependency('astal-network-0.1'),
        dependency('astal-bluetooth-0.1'),
        dependency('astal-apps-0.1'),
        dependency('gio-unix-2.0'),
        dependency('libadwaita-1', version: '>= 1.6.0'),
        dependency('libgtop-2.0'),
    ],
    link_args: ['-lm'], # Link math library
    install: true,
)