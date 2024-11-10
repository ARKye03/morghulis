blueprints = custom_target(
    'blueprints',
    input: files(
        'Mpris.blp',
        'OnScreenDisplay.blp',
        'SideDashboard.blp',
        'sdButton.blp',
        'Runner.blp',
        'RunnerButton.blp',
        'StatusBar.blp',
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