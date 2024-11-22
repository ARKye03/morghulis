blueprints = custom_target(
    'blueprints',
    input: files(
        'NavBar.blp',
        'OnScreenDisplay.blp',
        'CircularProgressBar.blp',
        # QuickMenu components
        'QuickMenu.blp',
        'QButton.blp',
        'PowerBox.blp',
        'Settings.blp',
        'SliderBox.blp',
        'Mpris.blp',
        # Runner components
        'Runner.blp',
        'RunnerButton.blp',
        # Notification components
        'NotifWindow.blp',
        'NotifPop.blp',
    ),
    output: '.',
    command: [
        find_program('blueprint-compiler'),
        'batch-compile',
        '@OUTPUT@',
        '@CURRENT_SOURCE_DIR@',
        '@INPUT@',
    ],
)