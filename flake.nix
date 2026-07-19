{
  description = "Morghulis";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      astal,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        version = builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile ./version);
        buildName = "morghulis";
        appName = "${buildName}-${version}";
        stdenv = pkgs.gcc14Stdenv;

        nix-utils = with pkgs; [
          nixfmt-rfc-style
        ];
        nix-morghulis = stdenv.mkDerivation {
          name = buildName;
          src = ./.;
          version = version;

          buildInputs =
            with pkgs;
            [
              pkg-config
            ]
            ++ gtk-utils
            ++ runtime-utils
            ++ compiler-utils
            ++ build-utils
            ++ astal-libs;

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
            license = licenses.mit;
            homepage = "https://github.com/ARKye03/morghulis";
            maintainers = with maintainers; [ ARKye03 ];
          };
        };
        fhs-morghulis = nix-morghulis.overrideAttrs {
          installPhase = ''
            mkdir -p $out/bin
            cp -r $TMPDIR/buildNix/src/${buildName} $out/bin/${appName}

            # Patch the binary
            ${pkgs.patchelf}/bin/patchelf --set-interpreter /lib64/ld-linux-x86-64.so.2 $out/bin/${appName}
            ${pkgs.patchelf}/bin/patchelf --set-rpath /lib:/usr/lib $out/bin/${appName}
            ${pkgs.patchelf}/bin/patchelf --shrink-rpath $out/bin/${appName}
          '';
        };
        pkg-tarball =
          pkgs.runCommand "morghulis-tarball"
            {
              src = ./.;
              buildInputs = [
                pkgs.gnutar
                pkgs.xz
              ];
            }
            ''
              # Create staging directory
              staging="$TMPDIR/staging"
              mkdir -p "$staging"

              # Define asset files
              filenames=(
                "data/desktop/com.github.ARKye03.morghulis.desktop.in"
              )

              # Copy binaries to staging
              cp ${fhs-morghulis}/bin/${appName} "$staging/"

              # Copy assets to staging with directory structure
              for filename in "''${filenames[@]}"; do
                mkdir -p "$staging/$(dirname "$filename")"
                cp "$src/$filename" "$staging/$filename"
              done

              # Create output directory
              mkdir -p $out

              # Create tarball from staging directory
              cd "$staging"
              tar --sort=name \
                  --owner=0 --group=0 \
                  --mtime='1970-01-01 00:00:00' \
                  -cJf "$out/morghulis-${version}.tar.xz" .

              sha256sum "$out/morghulis-${version}.tar.xz" > "$out/morghulis-${version}.tar.xz.sha256"
            '';
        gtk-utils = with pkgs; [
          gtk4
          gtk4-layer-shell
          libadwaita
          appstream
        ];
        runtime-utils = with pkgs; [
          gsound
          libgtop
          libportal
          cmark
          muparser
          libsoup_3
          wayland # libwayland-client + wayland-client.pc for generated protocol bindings
        ];
        compiler-utils = with pkgs; [
          vala
          vala-language-server
          vala-lint
          uncrustify
          dart-sass
          blueprint-compiler
          desktop-file-utils
          # Wayland protocol binding generation (src/Platform/Wayland). Protocol XMLs are
          # vendored in-repo, so only the toolchain is needed here.
          wayland-scanner
          python3 # wl-vapi-gen is a python3 script
          # NOTE: wl-vapi-gen (https://codeberg.org/kotontrion/wl-vapi-gen) is not
          # in nixpkgs. meson finds it on PATH; if absent it falls back to the
          # subprojects/wl-vapi-gen.wrap git subproject (needs network at setup).
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
          tray
          battery
          powerprofiles
          bluetooth
          wl
        ];
        shell =
          pkgs.mkShell.override
            {
              stdenv = stdenv;
            }
            {
              nativeBuildInputs =
                with pkgs.buildPackages;
                [
                  glfw
                  gobject-introspection
                ]
                ++ nix-utils
                ++ gtk-utils
                ++ runtime-utils
                ++ compiler-utils
                ++ build-utils
                ++ astal-libs;
              buildInputs = with pkgs; [
                pkg-config
                networkmanager
                glib
                gdk-pixbuf
              ];
              XCURSOR_THEME = "Bibata-Modern-Classic";
              XCURSOR_SIZE = "20";
            };
      in
      {
        packages = {
          default = nix-morghulis;
          fhs = fhs-morghulis;
          tarball = pkg-tarball;
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
