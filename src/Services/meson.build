# Backend service wrappers (no widgets).
project_resources += files(
    'CMark/Pango.vala',
    'Clipboard/Clipboard.vala',
    'Gamma/Gamma.vala',
    'Image/ImageLoader.vala',
    'ScreenRec/ScreenRecorder.vala',
    'Backlight/Backlight.vala',
)

install_data(
    'Backlight/backlight.rules',
    install_dir: get_option('sysconfdir') / 'udev' / 'rules.d',
    rename: '90-backlight.rules',
)
