project_resources += ['Main.vala']
project_args = []

# Auto-generate ensure_types(): forces GType registration for every class so
# Blueprint can instantiate custom widgets by name. build_always_stale keeps it
# fresh; the generator only rewrites on change, so no needless recompiles.
ensure_types_vala = custom_target(
    'ensure-types',
    output: 'ensure-types.vala',
    command: [
        find_program('python3'),
        files('../scripts/gen-ensure-types.py'),
        '@OUTPUT@',
        meson.current_source_dir(),
    ],
    build_always_stale: true,
)
project_resources += ensure_types_vala

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
    dependency('json-glib-1.0'),
    dependency('glycin-2'),
    dependency('glycin-gtk4-2')
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

subdir('App')
subdir('Widgets')
subdir('Services')
subdir('Platform')

subdir('NavBar')
subdir('PowerMenu')
subdir('Tray')
subdir('Notifications')
subdir('OnScreenDisplay')
subdir('QuickMenu')
subdir('Runner')
subdir('ScreenRecord')

# Blueprint files, colocated on disk with their .vala (paths relative to src/).
# Single source of truth: drives both the compiler and the gresource manifest,
# and the resource path mirrors the source path (ui/<here>.ui).
blp_rel = [
    'NavBar/NavBar.blp',
    'Notifications/NotificationContent.blp',
    'Notifications/NotificationCenter.blp',
    'Notifications/QNotifications.blp',
    'OnScreenDisplay/OnScreenDisplay.blp',
    'PowerMenu/PowerMenu.blp',
    'ScreenRecord/ScreenRecord.blp',
    'QuickMenu/AppSettings.blp',
    'QuickMenu/BatteryBox.blp',
    'QuickMenu/MprisPlayer.blp',
    'QuickMenu/PowerBox.blp',
    'QuickMenu/QAudioBox.blp',
    'QuickMenu/QAudioItem.blp',
    'QuickMenu/QBluetooth.blp',
    'QuickMenu/QBluetoothItem.blp',
    'QuickMenu/QButton.blp',
    'QuickMenu/QNetwork.blp',
    'QuickMenu/QNetworkItem.blp',
    'QuickMenu/QuickMenu.blp',
    'QuickMenu/Settings.blp',
    'Runner/Runner.blp',
    'Runner/Commands/AppsCmd.blp',
    'Runner/Commands/AppsCmdButton.blp',
    'Runner/Commands/ClipboardCmd.blp',
    'Runner/Commands/FilesCmd.blp',
    'Runner/Commands/HelpCmd.blp',
    'Runner/Commands/MathCmd.blp',
    'Runner/Commands/SysInfoCmd.blp',
    'Runner/Commands/SysInfoItem.blp',
    'Runner/Commands/WeatherCmd.blp',
]

# Compile all blueprints under a mirrored ui/ tree in the build dir.
blueprints = custom_target(
    'blueprints',
    input: files(blp_rel),
    output: 'ui',
    command: [
        find_program('blueprint-compiler'),
        'batch-compile',
        '@OUTPUT@',
        meson.current_source_dir(),
        '@INPUT@',
    ],
)

# Assemble the gresource manifest from the icon list (../data) + the blueprints.
ui_entries = ''
foreach r : blp_rel
    ui = r.replace('.blp', '.ui')
    ui_entries += '        <file preprocess="xml-stripblanks">ui/' + ui + '</file>\n'
endforeach

gresource_conf = configuration_data()
gresource_conf.set('ICON_ENTRIES', icon_entries)
gresource_conf.set('UI_ENTRIES', ui_entries)

gresource_xml = configure_file(
    input: gresource_template,
    output: project_name + '.gresource.xml',
    configuration: gresource_conf,
)

project_resources += gnome.compile_resources(
    project_name,
    gresource_xml,
    dependencies: [blueprints, scss],
    source_dir: [meson.current_build_dir(), data_source_dir],
)

executable(
    project_name,
    project_resources,
    vala_args: [
        '--gresourcesdir=' + meson.current_build_dir(),
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
