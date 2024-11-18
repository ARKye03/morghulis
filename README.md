# Morghulis

- [Morghulis](#morghulis)
  - [Requirements](#requirements)
  - [Installation](#installation)
    - [From source](#from-source)
    - [Arch Linux](#arch-linux)
  - [Usage](#usage)
  - [Development](#development)
    - [Nix](#nix)
  - [Features](#features)
  - [Preview](#preview)
  - [License](#license)

Desktop Shell created with GTK4, Libadwaita, and Astal.

## Requirements

- [Hyprland](https://hyprland.org/)
- [Vala](https://vala.dev/), [Meson](https://mesonbuild.com/), [Just](https://github.com/casey/just)
- [Astal](https://github.com/Aylur/astal)
- [Libadwaita](https://gitlab.gnome.org/GNOME/libadwaita)
- [Blueprint-Compiler](https://jwestman.pages.gitlab.gnome.org/blueprint-compiler/)
- [gtk4-layer-shell](https://github.com/wmww/gtk4-layer-shell)

## Installation

### From source

```shell
git clone https://github.com/ARKye03/morghulis
cd morghulis
just init
just install
```

### Arch Linux

Build and install using my `PKGBUILD` file:

```sh
mkdir /tmp/morghulis && cd /tmp/morghulis 
wget https://raw.githubusercontent.com/ARKye03/PKGBUILDS/refs/heads/main/morghulis-git/PKGBUILD
makepkg -si
```

Alternatively, use a binary from [releases](https://github.com/ARKye03/morghulis/releases).

## Usage

Morghulis is a desktop shell that uses Astal under the hood, so the astal cli is available to use, via `astal -i morghulis <command>`, nevertheless, the `morghulis-cli` called `morghulctl` is dedicated to this project itself.

```shell
morghulctl --help
```

> [!NOTE] The cli at the moment offers simple commands to start the application, toggle window, and show inspector.

## Development

```shell
just init
just
```

### Nix

Use `flake.nix` for development:

```shell
nix develop
```

Or run it with:

```shell
nix run github:ARKye03/morghulis -- --help
# For non-NixOS distro
nix run github:ARKye03/morghulis#fhs -- --help
```

## Features

- [x] Status Bar
  - [x] Workspace Switcher
  - [x] Focused Client
- [x] Quick Settings
  - [x] Mpris Media Player
  - [x] Power Buttons
  - [ ] (WIP) Bluetooth
  - [ ] (WIP) Network
  - [ ] (WIP) Brightness
- [x] Apps Runner
  - [x] (WIP) Handle Hyprland Clients
- [x] Notifications
  - [x] Center
  - [ ] (WIP) Popup
- [x] Power Menu (WIP)
- [x] OnScreenDisplay
  - [x] Audio
  - [x] (WIP) Brightness
- [x] Dynamic CSS (WIP)

## Preview

![Morghulis](public/morghulis.webp)

> [!NOTE] The preview uses the adwaita-dark theme and
>
> - [adw-gtk3](https://github.com/lassekongo83/adw-gtk3)

## License

Licensed under the WTFPL. See the [LICENSE](./LICENSE) file for details.
