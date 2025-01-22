project_resources += ['Main.vala', 'App.vala']
project_args = []

vapidir = meson.current_source_dir() + '/vapi/'

# Optional dependencies
astal_hyprland_dep = dependency('astal-hyprland-0.1', required: false)
astal_river_dep = dependency('astal-river-0.1', required: false)
astal_battery_dep = dependency('astal-battery-0.1', required: false)
astal_power_profiles_dep = dependency('astal-power-profiles-0.1', required: false)
libgtop_dep = dependency('libgtop-2.0', required: false)


deps = [
        dependency('gtk4'),
        dependency('gtk4-layer-shell-0'),
        dependency('astal-4-4.0'),
        dependency('astal-io-0.1'),
        dependency('libnm'),
        dependency('astal-wireplumber-0.1'),
        dependency('astal-mpris-0.1'),
        dependency('astal-tray-0.1'),
        dependency('astal-notifd-0.1'),
        dependency('astal-network-0.1'),
        dependency('astal-bluetooth-0.1'),
        dependency('astal-apps-0.1'),
        dependency('gio-unix-2.0'),
        dependency('libadwaita-1', version: '>= 1.6.0'),
    ]


# Add optional dependencies if found
if astal_hyprland_dep.found()
    deps += astal_hyprland_dep
endif

if astal_river_dep.found()
    deps += astal_river_dep
endif

if astal_battery_dep.found()
    deps += astal_battery_dep
endif

if astal_power_profiles_dep.found()
    deps += astal_power_profiles_dep
endif

if libgtop_dep.found()
    deps += libgtop_dep
endif

subdir('Modules')
subdir('NavBar')
subdir('Tray')
subdir('Notifications')
subdir('OnScreenDisplay')
subdir('QuickMenu')
subdir('Runner')
subdir('lib')

executable(
    project_name,
    project_resources,
    vala_args: [
        '--gresourcesdir=data/',
        '--vapidir=' + vapidir,
    ] + project_args,
    dependencies: deps,
    link_args: ['-lm'], # Link math library
    install: true,
)