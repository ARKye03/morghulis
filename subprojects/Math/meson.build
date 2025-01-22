project(
    'math',
    'c',
    version: '1.0',
    meson_version: '>= 1.4.0',
)

glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')

c_sources = files('evaluator.c', 'lexer.c', 'mpars.c', 'parser.c')
c_headers = files('ast.h', 'evaluator.h', 'lexer.h', 'mpars.h', 'parser.h')

resources = c_sources + c_headers

lib = shared_library(
    'mpars-1.0',
    resources,
    dependencies: [glib_dep, gobject_dep], 
    vala_header: 'mpars.h',
    vala_vapi: 'mpars-1.0.vapi',
    vala_gir: 'mpars-1.0.gir',
    install: true,
    install_dir: get_option('libdir'),
)

gnome = import('gnome')

gir = gnome.generate_gir(
    lib,
    sources: resources,
    namespace: 'Mpars',
    nsversion: '1.0',
    identifier_prefix: 'Mpars',
    symbol_prefix: 'mpars',
    includes: ['GObject-2.0'],
    install: true,
    install_dir_gir: get_option('datadir') / 'gir-1.0',
    install_dir_typelib: get_option('libdir') / 'girepository-1.0',
    header: 'mpars.h',
    export_packages: 'mpars-1.0',
    extra_args: [
        '--c-include=mpars.h',
        '--warn-all',
    ],
)

gnome.generate_vapi(
    'mpars-1.0',
    sources: [gir[0]],
    packages: ['glib-2.0'],
    install: true,
    install_dir: get_option('datadir') / 'vala' / 'vapi',
)

install_headers('mpars.h')

math_dep = declare_dependency(
    link_with: lib,
    dependencies: glib_dep,
    include_directories: include_directories('.'),
)