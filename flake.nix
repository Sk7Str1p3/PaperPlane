{
  description = ''
    Chat over Telegram on a modern and elegant client
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      crane,
      flake-utils,
      advisory-db,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        inherit (pkgs) lib;
        craneLib = crane.mkLib pkgs;

        # This filter prevent project from being rebuilded then changing
        # unrelated files like MDs
        filter' =
          path: _type:
          builtins.match (lib.concatStringsSep "|" [
            ".*po"
            ".+meson.+"
            ".*sh"
            ".*svg"
            ".*blp"
            ".*in"
            ".*xml"
            ".*ui"
            ".*css"
          ]) path != null;
        filter = path: type: (filter' path type) || (craneLib.filterCargoSources path type);
        src = lib.cleanSourceWith {
          src = ./.;
          inherit filter;
          name = "source";
        };

        common =
          with pkgs;
          let
            # Patch dependencies
            gtk4-papered = gtk4.overrideAttrs (prev: {
              patches = (prev.patches or [ ]) ++ [
                ./build-aux/gtk-reversed-list.patch
              ];
            });
            wrapPaperHook = buildPackages.wrapGAppsHook3.override {
              gtk3 = gtk4-papered;
            };
            libadwaita-papered = libadwaita.override {
              gtk4 = gtk4-papered;
            };
          in
          {
            inherit src;
            strictDeps = true;

            # Bunch of libraries required for package proper work
            buildInputs = with pkgs; [
              libshumate
              libadwaita-papered
              tdlib
              rlottie
              gst_all_1.gstreamer
              gst_all_1.gst-libav
              gst_all_1.gst-plugins-good
              gst_all_1.gst-plugins-base
            ];
            # Software required for projct build
            nativeBuildInputs = with pkgs; [
              pkg-config
              rustPlatform.bindgenHook
              (rustPlatform.buildRustPackage rec {
                pname = "cargo-post";
                version = "0.1.7";
                src = fetchFromGitHub {
                  owner = "phil-opp";
                  repo = "cargo-post";
                  rev = "v${version}";
                  hash = "sha256-ha83j6IjvwcRQ7lGKRsE4c2VOiB4Vl5aMXPF5dKeYww=";
                };
                cargoHash = "sha256-tzHP2r+l+n3d1DrMOwhVDqU221TQE1tx5OObQ6dAjlE=";
              })
              meson
              ninja
              blueprint-compiler
              desktop-file-utils
              wrapPaperHook
              libxml2.bin
            ];
          };

        # Build dependencies only, so we will be able to reuse them further
        cargoArtifacts = craneLib.buildDepsOnly common;

        # Build the actual crate itself, reusing the dependency
        # artifacts from above.
        paper-plane = craneLib.buildPackage (
          common
          // {
            inherit cargoArtifacts;
            cargoExtraArgs = "--no-default-features --features build";
          }
        );
      in
      {
        checks = {
          # Build the crate as part of `nix flake check` for convenience
          build = paper-plane;

          # Run clippy (and deny all warnings) on the crate source,
          # again, reusing the dependency artifacts from above.
          #
          # Note that this is done as a separate derivation so that
          # we can block the CI if there are issues here, but not
          # prevent downstream consumers from building our crate by itself.
          clippy = craneLib.cargoClippy (
            common
            // {
              inherit cargoArtifacts;
              cargoClippyExtraArgs = "--all-targets -- --deny warnings";
            }
          );

          docs = craneLib.cargoDoc (common // { inherit cargoArtifacts; });

          # Check formatting
          fmt = craneLib.cargoFmt { inherit src; };

          tomlFmt = craneLib.taploFmt {
            src = pkgs.lib.sources.sourceFilesBySuffices src [ ".toml" ];
            # taplo arguments can be further customized below as needed
            # taploExtraArgs = "--config ./taplo.toml";
          };

          # Audit dependencies
          audit = craneLib.cargoAudit { inherit src advisory-db; };

          # Audit licenses
          deny = craneLib.cargoDeny { inherit src; };
        };

        packages = {
          default = paper-plane;
        };

        apps.default = flake-utils.lib.mkApp { drv = paper-plane; };

        devShells.default = craneLib.devShell {
          # Inherit inputs from checks.
          checks = self.checks.${system};

          # Additional dev-shell environment variables can be set directly
          # MY_CUSTOM_DEVELOPMENT_VAR = "something else";

          # Extra inputs can be added here; cargo and rustc are provided by default.
          packages =
            with pkgs;
            [
              # pkgs.ripgrep
              nixd
              nixfmt-rfc-style
            ]
            # in case you want build without nix
            ++ common.nativeBuildInputs
            ++ common.buildInputs;
        };
      }
    );
}
