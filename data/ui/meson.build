targets = files(
    'CircularProgressBar.blp',
    'Mpris.blp',
    'NavBar.blp',
    'NotifPop.blp',
    'NotifWindow.blp',
    'OnScreenDisplay.blp',
    'PowerBox.blp',
    'QButton.blp',
    'QuickMenu.blp',
    'Runner.blp',
    'RunnerButton.blp',
    'Settings.blp',
    'SliderBox.blp',
)

blueprints = custom_target(
    'blueprints',
    input: targets,
    output: '.',
    command: [
        find_program('blueprint-compiler'),
        'batch-compile',
        '@OUTPUT@',
        '@CURRENT_SOURCE_DIR@',
        '@INPUT@',
    ],
)