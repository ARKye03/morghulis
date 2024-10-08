sass = find_program('sass')

scss_deps = files(
    'main.scss',
)

scss = custom_target(
    'scss',
    input: 'main.scss',
    output: 'morghulis.css',
    command: [
        sass,
        '@INPUT@',
        '@OUTPUT@',
    ],
    depend_files: scss_deps,
)