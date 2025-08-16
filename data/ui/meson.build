blps = files(
    'NavBar.blp',
    'NotificationContent.blp',
    'OnScreenDisplay.blp',
    'PowerMenu.blp',
)

subdir('QuickMenu')
subdir('Runner')

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