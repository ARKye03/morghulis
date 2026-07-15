# Generate Vala bindings for the Wayland protocols consumed by morghulis.
# Pipeline per protocol: wayland-scanner emits the C client header + private
# code, wl-vapi-gen emits the matching .vapi. All three feed the executable.

wl_scanner = find_program('wayland-scanner')

wl_vapi_gen = find_program('wl-vapi-gen', required: false)
if not wl_vapi_gen.found()
    subproject('wl-vapi-gen')
    wl_vapi_gen = find_program('wl-vapi-gen')
endif

wl_protocols = [
    'ext-data-control-v1',
    'wlr-gamma-control-unstable-v1',
]

foreach proto : wl_protocols
    xml = meson.current_source_dir() / 'protocols' / proto + '.xml'
    header_name = proto + '-client-protocol.h'

    proto_header = custom_target(
        proto + '-client-header',
        input: xml,
        output: header_name,
        command: [wl_scanner, 'client-header', '@INPUT@', '@OUTPUT@'],
    )

    proto_code = custom_target(
        proto + '-code',
        input: xml,
        output: proto + '-protocol.c',
        command: [wl_scanner, 'private-code', '@INPUT@', '@OUTPUT@'],
    )

    proto_vapi = custom_target(
        proto + '-vapi',
        input: xml,
        output: proto + '.vapi',
        command: [
            wl_vapi_gen,
            '--protocol', '@INPUT@',
            '--vapi', '@OUTPUT@',
            '--cheader', header_name,
        ],
    )

    project_resources += [proto_header, proto_code, proto_vapi]
endforeach
