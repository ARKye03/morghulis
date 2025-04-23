project_resources += files('backlight.vala')

install_data(
  'backlight.rules',
  install_dir: get_option('sysconfdir') / 'udev' / 'rules.d',
  rename: '90-backlight.rules'
)

meson.add_install_script('reload_udev_rules.sh')