blps = files(
    'BatteryBox.blp',
    'MprisPlayer.blp',
    'NavBar.blp',
    'NotificationItem.blp',
    'OnScreenDisplay.blp',
    'PowerBox.blp',
    'PowerMenu.blp',
    'QAudioBox.blp',
    'QAudioItem.blp',
    'QBluetooth.blp',
    'QBluetoothItem.blp',
    'QButton.blp',
    'QNetwork.blp',
    'QNotifications.blp',
    'QuickMenu.blp',
    'Runner.blp',
    'RunnerButton.blp',
    'Settings.blp',
)

subdir('SysInfo')

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