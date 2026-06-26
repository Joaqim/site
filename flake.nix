{
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://speedy.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "speedy.cachix.org-1:GtGlHdmJ8q1MzD40sbY45hVv3Xws0RhDp/4bac4tGKQ="
    ];
  };

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    # Provides some nice helpers for multiple system compatibility
    flake-utils.url = "github:numtide/flake-utils";

    # Generate Javascript, HTML and CSS for personal blog
    speedy = {
      url = "gitlab:mplanchard/mplanchard.gitlab.io/master";
      # No need for extended compatibility
      inputs.flake-compat.follows = "";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (
              final: prev:
              let
                inherit (inputs.speedy.packages.${system}) speedy;
                build = pkgs.writeShellScriptBin "build" ''
                  [ -d ./public ] && rm -r ./public
                  speedy generate
                '';
              in
              {
                inherit build;
                speedy = speedy.overrideAttrs (_: {
                  patches = [
                    ./0001-change-defaults.patch
                  ];
                  postPatch = ''
                    rm -r ./templates
                    cp -RL --no-preserve=mode ${./templates} ./templates
                  '';
                  meta.mainProgram = "speedy";
                });
                serve = pkgs.writeShellScriptBin "serve" ''
                  ${pkgs.lib.getExe build}
                  speedy run &
                  trap 'jobs -p | xargs kill' EXIT
                  watchexec \
                      --watch posts \
                      --watch static \
                      ${pkgs.lib.getExe final.speedy} generate
                '';
              }
            )
          ];
        };
        highlightjs = pkgs.callPackage ./highlightjs.nix { };
      in
      # "unpack" the pkgs attrset into the parent namespace
      with pkgs;
      {
        devShells = {
          default = mkShell {
            buildInputs = [
              bashInteractive
              coreutils
              watchexec

              speedy
            ];
            ENVIRONMENT = "dev";
            shellHook = ''
              [ -d ./static/js/vendor/highlight ] || cp -RL --no-preserve=mode "${highlightjs}" ./static/js/vendor/highlight
            '';
          };
          ci = mkShell {
            buildInputs = [
              bashNonInteractive
            ];
          };
        };

        apps =
          let
            mkApp = pkg: {
              type = "app";
              program = lib.getExe pkg;
            };
          in
          {
            build = mkApp build;
            serve = mkApp serve;
            default = mkApp serve;
          };

        packages = rec {
          site = callPackage ./site.nix { inherit speedy highlightjs; };
          default = site;
        };
      }
    );
}
