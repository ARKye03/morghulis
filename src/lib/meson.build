c_sources = files('lexer.c', 'parser.c', 'evaluator.c')
c_headers = files('lexer.h', 'parser.h', 'evaluator.h', 'ast.h')

resources = c_sources + c_headers

lib = static_library(
    'math-1.0',
    resources,
)

math_dep = declare_dependency(
    link_with: lib,
    include_directories: include_directories('.')
)