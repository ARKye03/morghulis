subdir('scss')
subdir('desktop')

# Install GSettings schema
install_data(
    'com.arkye.morghulis.gschema.xml',
    install_dir: get_option('datadir') / 'glib-2.0' / 'schemas',
)

fs = import('fs')

# Icon assets exposed under the icons/scalable/actions prefix; alias is the basename.
# The .ui entries and final gresource assembly happen in ../src/meson.build, where
# the blueprint list (colocated with the .vala) is known.
icon_paths = [
    'assets/bell-minus-symbolic.svg',
    'assets/NavBar/terminal-symbolic.svg',
    'assets/NavBar/browser-symbolic.svg',
    'assets/NavBar/code-symbolic.svg',
    'assets/NavBar/explorer-symbolic.svg',
    'assets/NavBar/docs-symbolic.svg',
    'assets/NavBar/social-symbolic.svg',
    'assets/NavBar/media-symbolic.svg',
    'assets/NavBar/settings-symbolic.svg',
    'assets/NavBar/gaming-symbolic.svg',
    'assets/Runner/math-symbolic.svg',
    'assets/Runner/weather-symbolic.svg',
    'assets/System/hibernate-symbolic.svg',
    'assets/System/logout-symbolic.svg',
    'assets/System/reboot-symbolic.svg',
    'assets/System/shutdown-symbolic.svg',
    'assets/System/suspend-symbolic.svg',
    'assets/System/lockscreen-symbolic.svg',
    'assets/SysInfo/cpu-symbolic.svg',
    'assets/SysInfo/device-desktop-symbolic.svg',
    'assets/SysInfo/device-floppy-symbolic.svg',
    'assets/SysInfo/mem-ram-symbolic.svg',
    'assets/SysInfo/network-symbolic.svg',
    'assets/SysInfo/swap-ram-symbolic.svg',
    'assets/SysInfo/timeline-symbolic.svg',
    'assets/SysInfo/linux-symbolic.svg',
]

icon_entries = ''
foreach p : icon_paths
    icon_entries += '        <file alias="' + fs.name(p) + '">' + p + '</file>\n'
endforeach

# Exposed to ../src/meson.build for the final gresource assembly.
gresource_template = files('gresource.xml.in')
data_source_dir = meson.current_source_dir()
