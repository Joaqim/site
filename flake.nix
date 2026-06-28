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
      url = "gitlab:joaqim/speedy/master";
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
                generate-icons = pkgs.writeShellScriptBin "generate-icons" (
                  builtins.readFile ./scripts/generate-icons.sh
                );
                # Adapted from: https://stackoverflow.com/a/76264351
                get-first-github-commit-date = pkgs.writeShellApplication {
                  name = "get-first-github-commit-date";
                  runtimeInputs = with pkgs; [
                    curlMinimal
                    gawk
                  ];
                  text = builtins.readFile ./scripts/get-first-github-commit-date.sh;
                };
                create-new-post = pkgs.writeShellScriptBin "create-new-post" (
                  builtins.readFile ./scripts/create-new-post.sh
                );
                create-project-from-github = pkgs.writeShellScriptBin "create-project-from-github" (
                  builtins.readFile ./scripts/create-project-from-github.sh
                );
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

              dprint
              typos

              speedy
              generate-icons
              create-new-post
              get-first-github-commit-date
              create-project-from-github
            ];
            ENVIRONMENT = "dev";
            AUTHOR_FULLNAME = "Joaqim Planstedt";
            URL_BASE = "blog.joaqim.com";
            PROJECTS_SORT_ORDER = "site,speedy,plan,dotfiles,jqpkgs,balanced-dice-avr";

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
            icons = mkApp generate-icons;
            default = mkApp serve;
          };

        packages = rec {
          site = callPackage ./site.nix { inherit speedy highlightjs; };
          default = site;
        };
      }
    );
}
