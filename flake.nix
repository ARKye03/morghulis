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
              gobject-introspection
              glfw-wayland
            ] ++ nix-utils;
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
