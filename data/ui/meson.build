blps = files(
    'NavBar.blp',
    'NotificationItem.blp',
    'OnScreenDisplay.blp',
    'PowerMenu.blp',
    'Runner.blp',
    'RunnerButton.blp',
)

subdir('SysInfo')
subdir('QuickMenu')

blueprints = custom_target(
    'blueprints',
    input: blps,
    output: '.',
    command: [
        find_program('blueprint-compiler'),
        'batch-compile',
        '@OUTPUT@',
        '@CURRENT_SOURCE_DIR@',
        '@INPUT@',
    ],
)