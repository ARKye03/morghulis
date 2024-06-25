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
            nativeBuildInputs = with pkgs; [
              gtk4-layer-shell
              vala
              vala-language-server
              uncrustify
              muon
              meson
              ninja
              pkg-config
              glfw-wayland
            ] ++ nix-utils;
            buildInputs = with pkgs; [
              gtk4
              # gobject-introspection
              glib
              gdk-pixbuf
              json-glib
            ];
            shellHook = ''
              export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
            '';
          };
        in
        {
          devShells.default = shell;
        }
      );
}
