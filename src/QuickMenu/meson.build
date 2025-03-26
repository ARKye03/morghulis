project_resources += files(
    'QuickMenu.vala',
    'QNetwork.vala',
    'QBluetooth.vala',
    'QBluetoothItem.vala',
    'BatteryBox.vala',
    'MprisPlayer.vala',
    'QButton.vala',
    'PowerBox.vala',
    'Settings.vala',
    'QAudioBox.vala',
    'QAudioItem.vala',
    'SysInfo.vala',
)

if astal_battery_dep.found()
    project_args += ['--define=battery']
endif

if astal_power_profiles_dep.found()
    project_args += ['--define=power-profiles']
endif