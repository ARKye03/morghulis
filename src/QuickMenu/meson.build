project_resources += files(
    'BatteryBox.vala',
    'MprisPlayer.vala',
    'PowerBox.vala',
    'QAudioBox.vala',
    'QAudioItem.vala',
    'QBluetooth.vala',
    'QBluetoothItem.vala',
    'QButton.vala',
    'QNetwork.vala',
    'QuickMenu.vala',
    'Settings.vala',
)

if astal_battery_dep.found()
    project_args += ['--define=battery']
endif

if astal_power_profiles_dep.found()
    project_args += ['--define=power-profiles']
endif