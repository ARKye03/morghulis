
# Morghulis
- [Morghulis](#morghulis)
  - [Requirements](#requirements)
  - [Usage](#usage)
    - [Development](#development)
    - [Installation](#installation)
  - [Features](#features)
  - [License](#license)

Desktop Shell, created with [gtk4-layer-shell](https://github.com/wmww/gtk4-layer-shell).

## Requirements

- [Hyprland](https://hyprland.org/)
- [Vala](https://vala.dev/), [Meson](https://mesonbuild.com/), [Make](https://www.gnu.org/software/make/)
- [Astal](https://github.com/Aylur/astal)

## Usage

```shell
git clone https://github.com/ARKye03/morghulis
cd morghulis
meson setup build
```

### Development

> [!WARNING]  
> The flake.nix environment is not suitable for building this project, not anymore, for now.

```shell
make
```

### Installation

```shell
meson install -C build
```

## Features

- [x] Status Bar
    - [x] Workspace Switcher
    - [x] Media Player
    - [x] Volume Controller
    - [x] Focused Client
- [ ] Notifications
    - [ ] Center
    - [ ] Popup
- [ ] OnScreenDisplay
  - [ ] Audio
  - [ ] Brightness
- [ ] Apps Runner
- [ ] Quick Settings
- [ ] Dynamic CSS

## License

This project is licensed under the WTFPL, see the [LICENSE](./LICENSE) file for more details.
