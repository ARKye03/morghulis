{
  description = "my project description";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nix-utils = with pkgs; [
            nil
            nixpkgs-fmt
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
              pkg-config
              glfw-wayland
              gobject-introspection
              blueprint-compiler
            ] ++ nix-utils;
            # buildInputs = with pkgs; [
            #   glib
            #   gdk-pixbuf
            #   json-glib
            # ];
            shellHook = ''
              # export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
              export GTK_THEME=adw-gtk3:dark # Forcing to use Arch Linux's active theme
            '';
          };
        in
        {
          devShells.default = shell;
        }
      );
}
