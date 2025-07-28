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
              meson
              ninja
              blueprint-compiler
              desktop-file-utils
              wrapPaperHook
              libxml2.bin
            ];
          };
      in
      {
        devShells.default = craneLib.devShell {
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
