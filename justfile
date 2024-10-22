APP_NAME := "morghulis"
BIN_DIR := "build"

run: build
    ./{{BIN_DIR}}/src/{{APP_NAME}}

init:
    meson setup build

rinit:
    meson setup --reconfigure build

build:
    ninja -C {{BIN_DIR}}

clean:
    rm -rf {{BIN_DIR}}