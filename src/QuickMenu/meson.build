project_resources += files(
    'QuickMenu.vala',
    'QNetwork.vala',
    'QBluetooth.vala',
    'QBluetoothItem.vala',
    'QPowerProfiles.vala',
    'Mpris.vala',
    'QButton.vala',
    'PowerBox.vala',
    'Settings.vala',
    'SliderBox.vala',
)

if astal_battery_dep.found()
    project_args += ['--define=battery']
endif

if astal_power_profiles_dep.found()
    project_args += ['--define=power-profiles']
endif

if libgtop_dep.found()
    project_resources += files('SysInfo.vala')
endif