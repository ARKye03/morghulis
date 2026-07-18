APP_NAME := "morghulis"
BIN_DIR := "build"
CLI_APP_NAME := "morghulctl"

run: build
    glib-compile-schemas --targetdir={{BIN_DIR}}/data data
    GSETTINGS_SCHEMA_DIR=$(pwd)/{{BIN_DIR}}/data ./{{BIN_DIR}}/src/{{APP_NAME}}

cli: build
    ./{{BIN_DIR}}/cli/{{CLI_APP_NAME}}

init:
    #!/usr/bin/env bash
    set -euo pipefail
    # arch-meson runs with --wrap-mode nodownload, so fetch the wl-vapi-gen
    # subproject up front when it isn't already available on PATH.
    if ! command -v wl-vapi-gen >/dev/null 2>&1 && [ ! -f subprojects/wl-vapi-gen/meson.build ]; then
        meson subprojects download wl-vapi-gen
    fi
    arch-meson build

rinit:
    meson setup --reconfigure build

build:
    ninja -C {{BIN_DIR}}

dist:
    meson -C {{BIN_DIR}} --no-tests dist

install:
    meson install -C {{BIN_DIR}}

uninstall:
    ninja uninstall -C {{BIN_DIR}}

clean:
    ninja clean -C {{BIN_DIR}}

prune:
    rm -rf {{BIN_DIR}}
