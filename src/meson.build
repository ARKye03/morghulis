project_resources += ['Main.vala']
project_args = []

vapidir = meson.current_source_dir() + '/vapi/'

# Optional dependencies
astal_hyprland_dep = dependency('astal-hyprland-0.1', required: false)
wl_dep = dependency('wayland-client')
astal_wl_dep = dependency('astal-wl-0.1', required: false)
astal_river_dep = dependency('astal-river-0.1', required: false)
astal_battery_dep = dependency('astal-battery-0.1', required: false)
astal_power_profiles_dep = dependency('astal-power-profiles-0.1', required: false)

deps = [
    dependency('gtk4'),
    dependency('gtk4-layer-shell-0'),
    dependency('gsound'),
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
    dependency('libgtop-2.0'),
    dependency('libportal'),
    dependency('libcmark'),
    dependency('muparser'),
    dependency('libsoup-3.0'),
    dependency('json-glib-1.0')
]

# wayland-client MUST come after gtk4-layer-shell-0 in the link line:
# gtk4-layer-shell interposes libwayland-client symbols and only works when
# linked before it. Appending here (rather than prepending) preserves that.
deps += wl_dep

# Add optional dependencies if found
if astal_hyprland_dep.found()
    deps += astal_hyprland_dep
endif

if astal_river_dep.found()
    deps += [astal_river_dep, astal_wl_dep]
endif

if astal_battery_dep.found()
    deps += astal_battery_dep
endif

if astal_power_profiles_dep.found()
    deps += astal_power_profiles_dep
endif

subdir('NavBar')
subdir('PowerMenu')
subdir('Tray')
subdir('Notifications')
subdir('OnScreenDisplay')
subdir('QuickMenu')
subdir('Runner')
subdir('ScreenRecord')

executable(
    project_name,
    project_resources,
    vala_args: [
        '--gresourcesdir=data/',
        '--vapidir=' + vapidir,
        '--pkg=posix',
        '--pkg=linux',
    ]
    + project_args,
    c_args: '-w',
    dependencies: deps,
    link_args: ['-lm'], # Link math library
    install: true,
)
