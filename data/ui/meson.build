blueprints = custom_target(
    'blueprints',
    input: files(
        'ImageFrame.blp',
        'Mpris.blp',
        'OnScreenDisplay.blp',
        'QuickSettings.blp',
        'QuickSettingsButton.blp',
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