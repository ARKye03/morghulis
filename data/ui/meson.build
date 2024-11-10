blueprints = custom_target(
    'blueprints',
    input: files(
        'StatusBar.blp',
        'OnScreenDisplay.blp',
        # SideDashboard components
        'SideDashboard.blp',
        'sdButton.blp',
        'sdPowerBox.blp',
        'sdSettings.blp',
        'Mpris.blp',
        # Runner components
        'Runner.blp',
        'RunnerButton.blp',
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