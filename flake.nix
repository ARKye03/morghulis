{
  description = "Morghulis";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    astal.url = "github:aylur/astal";
  };

  outputs = { self, nixpkgs, flake-utils, astal}:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nix-utils = with pkgs; [
            nixd
            nixpkgs-fmt
          ];
          astal-lib = astal.packages.${system}.default;
          shell = pkgs.mkShell {
            nativeBuildInputs = with pkgs.buildPackages; [
              gtk4
              gtk4-layer-shell
              vala
              vala-language-server
              uncrustify
              muon
              meson
              ninja
              glfw-wayland
              gobject-introspection
              blueprint-compiler
            ] ++ nix-utils;
            buildInputs = with pkgs; [
              pkg-config
              glib
              gdk-pixbuf
              json-glib
              astal-lib
            ];
            shellHook = /* shell */ ''
              export LD_LIBRARY_PATH=
              export GTK_THEME=adw-gtk3:dark
              export XCURSOR_THEME="Catppuccin-Mocha-Dark"
              # export PKG_CONFIG_PATH=/usr/lib/pkgconfig:$PKG_CONFIG_PATH
            '';
          };
        in
        {
          apps.default = {
            type = "app";
            program = "build/src/com.github.ARKye03.zoore_layer";
          };
          devShells.default = shell;
        }
      );
}
