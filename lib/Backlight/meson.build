project_resources += files('backlight.vala')

install_data(
  'backlight.rules',
  install_dir: get_option('sysconfdir') / 'udev' / 'rules.d',
  rename: '90-backlight.rules'
)