# Single source of truth for Blueprint files (paths relative to this dir).
# Feeds both the blueprint compiler and the generated gresource manifest in
# ../meson.build, so a new UI only needs one line here.
blp_rel = [
    'NavBar.blp',
    'NotificationContent.blp',
    'OnScreenDisplay.blp',
    'PowerMenu.blp',
    'ScreenRecord.blp',
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
    'QuickMenu/QNotifications.blp',
    'QuickMenu/QuickMenu.blp',
    'QuickMenu/Settings.blp',
    'Runner/AppsCmd.blp',
    'Runner/AppsCmdButton.blp',
    'Runner/HelpCmd.blp',
    'Runner/MathCmd.blp',
    'Runner/Runner.blp',
    'Runner/SysInfoCmd.blp',
    'Runner/SysInfoItem.blp',
    'Runner/WeatherCmd.blp',
]

blps = files(blp_rel)

blueprints = custom_target(
    'blueprints',
    input: blps,
    output: '.',
    command: [
        find_program('blueprint-compiler'),
        'batch-compile',
        '@OUTPUT@',
        '@CURRENT_SOURCE_DIR@',
        '@INPUT@',
    ],
)
