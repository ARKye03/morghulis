project_resources += files('NavBar.vala')

if astal_hyprland_dep.found()
    project_resources += files('HyprWorkspaces.vala')
    project_args += ['--define=hyprland']
endif

if astal_river_dep.found()
    project_resources += files('RiverTags.vala')
    project_args += ['--define=river']
endif