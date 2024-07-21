{
  description = "my project description";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    astal-hyprland.url = "github:astal-sh/hyprland";
    astal-mpris.url = "github:astal-sh/mpris";
    astal-notifd.url = "github:astal-sh/notifd";
  };

  outputs = { self, nixpkgs, flake-utils, astal-hyprland, astal-mpris, astal-notifd }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nix-utils = with pkgs; [
            nil
            nixpkgs-fmt
          ];
          astalServices = [

            (astal-hyprland.packages.${system}.default.overrideAttrs
              {
                patches = [ ./astal.patch ];
              })

            (astal-mpris.packages.${system}.default.overrideAttrs
              {
                patches = [ ./astal.patch ];
              })
            astal-notifd.packages.${system}.default
          ];
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
              libpulseaudio
              pkg-config
              glib
              gdk-pixbuf
              json-glib
            ] ++ astalServices;
            shellHook = /* shell */ ''
              export LD_LIBRARY_PATH=
              export GTK_THEME=adw-gtk3:dark # Forcing to use Arch Linux's active theme
              export XCURSOR_THEME="Catppuccin-Mocha-Dark"
              # export PKG_CONFIG_PATH=/usr/lib/pkgconfig:$PKG_CONFIG_PATH
            '';
          };
        in
        {
          apps.${system}.zoore = flake-utils.lib.mkApp {
            drv = pkgs.stdenv.mkDerivation {
              name = "zoore";
              # Assuming `build/src/com.github.ARKye03.zoore_layer` is a source directory
              # You need to ensure this derivation actually builds your application
              # This is a placeholder for the build instructions
              buildInputs = [ pkgs.gcc ]; # Example dependency
              buildPhase = "echo Building..."; # Placeholder build command
              installPhase = ''
                mkdir -p $out/bin
                cp -r build/src/com.github.ARKye03.zoore_layer $out/bin/zoore # Adjust this to your actual build output
              '';
            };
          };
          devShells.default = shell;
        }
      );
}
