{
  description = "Morghulis";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, astal }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          appName = "morghulis";
          nix-utils = with pkgs; [
            nixd
            nixpkgs-fmt
          ];
          morghulis = pkgs.stdenv.mkDerivation {
            name = appName;
            src = ./.;
            version = builtins.readFile ./version;

            buildInputs = with pkgs;  [
              pkg-config
            ] ++ nix-utils ++ gtk-utils ++ compiler-utils ++ build-utils ++ astal-libs;

            buildPhase = ''
              mkdir -p $TMPDIR/buildNix
              cd $TMPDIR/buildNix
              meson setup $TMPDIR/buildNix $src
              ninja -C $TMPDIR/buildNix
            '';

            installPhase = ''
              mkdir -p $out/bin
              cp -r $TMPDIR/buildNix/src/${appName} $out/bin/${appName}
              chmod +x $out/bin/${appName}
            '';

            meta = with pkgs.lib; {
              description = "A Desktop Shell for Wayland";
              license = licenses.wtfpl;
              homepage = "https://github.com/ARKye03/morghulis";
              maintainers = with maintainers; [ ARKye03 ];
            };
          };
          gtk-utils = with pkgs; [
            gtk4
            gtk4-layer-shell
            libadwaita
          ];
          compiler-utils = with pkgs; [
            vala
            vala-language-server
            uncrustify
          ];
          build-utils = with pkgs.buildPackages; [
            muon
            meson
            ninja
          ];
          astal-libs = with astal.packages.${system}; [
            hyprland
            wireplumber
            mpris
            network
            apps
            bluetooth
          ];
          shell = pkgs.mkShell {
            nativeBuildInputs = with pkgs.buildPackages; [
              glfw-wayland
              gobject-introspection
              blueprint-compiler
            ]
            ++ nix-utils
            ++ gtk-utils
            ++ compiler-utils
            ++ build-utils
            ++ astal-libs;
            buildInputs = with pkgs; [
              pkg-config
              networkmanager
              glib
              gdk-pixbuf
              json-glib
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
            program = "${morghulis}/bin/${appName}";
          };
          devShells.default = shell;
        }
      );
}
