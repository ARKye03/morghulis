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
          version = builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile ./version);
          buildName = "morghulis";
          appName = "${buildName}-${version}";
          stdenv = pkgs.gcc14Stdenv;

          nix-utils = with pkgs; [
            nixd
            nixpkgs-fmt
          ];
          nix-morghulis = stdenv.mkDerivation {
            name = buildName;
            src = ./.;
            version = version;

            buildInputs = with pkgs;  [
              pkg-config
            ] ++ gtk-utils ++ compiler-utils ++ build-utils ++ astal-libs;

            buildPhase = ''
              mkdir -p $TMPDIR/buildNix
              cd $TMPDIR/buildNix
              meson setup $TMPDIR/buildNix $src
              ninja -C $TMPDIR/buildNix
            '';

            installPhase = ''
              mkdir -p $out/bin
              cp -r $TMPDIR/buildNix/src/${buildName} $out/bin/${appName}
              chmod +x $out/bin/${appName}
            '';

            meta = with pkgs.lib; {
              description = "A Desktop Shell for Wayland";
              license = licenses.wtfpl;
              homepage = "https://github.com/ARKye03/morghulis";
              maintainers = with maintainers; [ ARKye03 ];
            };
          };
          fhs-morghulis = nix-morghulis.overrideAttrs {
            installPhase = ''
              mkdir -p $out/bin
              cp -r $TMPDIR/buildNix/src/${buildName} $out/bin/${appName}
              ${pkgs.patchelf}/bin/patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 $out/bin/${appName}
              ${pkgs.patchelf}/bin/patchelf --set-rpath /lib:/usr/lib $out/bin/${appName}
              ${pkgs.patchelf}/bin/patchelf --shrink-rpath $out/bin/${appName}
              chmod +x $out/bin/${appName}
            '';
          };
          gtk-utils = with pkgs; [
            gtk4
            gtk4-layer-shell
            libadwaita
          ];
          compiler-utils = with pkgs; [
            vala
            vala-language-server
            vala-lint
            uncrustify
            dart-sass
            blueprint-compiler
            git-cliff
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
            notifd
            river
            apps
            bluetooth
          ];
          shell = pkgs.mkShell.override
            {
              stdenv = stdenv;
            }
            {
              nativeBuildInputs = with pkgs.buildPackages; [
                glfw-wayland
                gobject-introspection
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
              GTK_THEME = "adw-gtk3:dark";
              XCURSOR_THEME = "Bibata-Modern-Classic";
              XCURSOR_SIZE = "20";
            };
        in
        {
          packages = {
            default = nix-morghulis;
            fhs = fhs-morghulis;
          };
          apps = {
            default = {
              type = "app";
              program = "${nix-morghulis}/bin/${appName}";
            };
            fhs = {
              type = "app";
              program = "${fhs-morghulis}/bin/${appName}";
            };
          };
          devShells.default = shell;
        }
      );
}
