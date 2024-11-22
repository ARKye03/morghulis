blueprints = custom_target(
    'blueprints',
    input: files(
        'NavBar.blp',
        'OnScreenDisplay.blp',
        'CircularProgressBar.blp',
        # SideDashboard components
        'SideDashboard.blp',
        'sdButton.blp',
        'sdPowerBox.blp',
        'sdSettings.blp',
        'sdSliderBox.blp',
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