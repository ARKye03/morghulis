APP_NAME := "morghulis"
BIN_DIR := "build"
CLI_APP_NAME := "morghulctl"

run: build
    ./{{BIN_DIR}}/src/{{APP_NAME}}

cli: build
    ./{{BIN_DIR}}/cli/{{CLI_APP_NAME}}

init:
    meson setup build

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