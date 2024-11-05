# Morghulis

- [Morghulis](#morghulis)
  - [Requirements](#requirements)
  - [Usage](#usage)
    - [Development](#development)
    - [Installation](#installation)
    - [Nix](#nix)
    - [Arch Linux](#arch-linux)
  - [Features](#features)
  - [Preview](#preview)
  - [License](#license)

Desktop Shell created with GTK4, Blueprint, and Vala.

## Requirements

- [Hyprland](https://hyprland.org/)
- [Vala](https://vala.dev/), [Meson](https://mesonbuild.com/), [Just](https://github.com/casey/just)
- [Astal](https://github.com/Aylur/astal)
- [Libadwaita](https://gitlab.gnome.org/GNOME/libadwaita)
- [Blueprint-Compiler](https://jwestman.pages.gitlab.gnome.org/blueprint-compiler/)
- [gtk4-layer-shell](https://github.com/wmww/gtk4-layer-shell)

## Usage

Clone the repository and set up the build environment:

```shell
git clone https://github.com/ARKye03/morghulis
cd morghulis
meson setup build
```

Alternatively, use a binary from [releases](https://github.com/ARKye03/morghulis/releases).

### Development

```shell
just init
just
```

### Installation

```shell
meson install -C build
morghulis --help
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

### Arch Linux

Build and install using the `PKGBUILD` file:

```shell
mkdir morghulis_pkg && cd morghulis_pkg
wget https://raw.githubusercontent.com/ARKye03/PKGBUILDS/refs/heads/main/morghulis/git/PKGBUILD
makepkg -si
```

## Features

- Status Bar
  - Workspace Switcher
  - Focused Client
- Socket Service
- Quick Settings
  - Media Player
  - Power Buttons
  - (WIP) Bluetooth, Network (VPN), Brightness
- Apps Runner
  - (WIP) Handle Hyprland Clients
- Notifications
  - (WIP) Center, Popup
- Power Menu
- OnScreenDisplay
  - Audio
  - (WIP) Brightness
- Dynamic CSS (WIP)

## Preview

![Morghulis](public/morghulis.webp)

> Note: The preview uses the adw-gtk One-Dark theme.

## License

Licensed under the WTFPL. See the [LICENSE](./LICENSE) file for details.
