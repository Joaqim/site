{
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    # Extended utilities for working with nix flake modules
    flake-parts.url = "github:hercules-ci/flake-parts";
    # Generate Javascript, HTML and CSS for personal blog
    speedy = {
      url = "gitlab:joaqim/speedy/master";
      # No need for extended compatibility
      inputs.flake-compat.follows = "";
    };
    # https://nixos.asia/en/treefmt
    treefmt-nix.url = "github:numtide/treefmt-nix";
    flake-root.url = "github:srid/flake-root";
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-parts,
      treefmt-nix,
      flake-root,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;
      imports = [
        treefmt-nix.flakeModule
        flake-root.flakeModule
      ];

      perSystem =
        {
          system,
          lib,
          config,
          pkgs,
          ...
        }:
        {
          # Auto formatters. This also adds a flake check to ensure that the
          # source tree was auto formatted.
          treefmt.config = {
            inherit (config.flake-root) projectRootFile;
            package = pkgs.treefmt;
            programs = {
              dprint = {
                enable = true;
                includes = [ "**/*.md" ];
                settings = {
                  plugins = pkgs.dprint-plugins.getPluginList (
                    plugins: with plugins; [
                      dprint-plugin-markdown
                    ]
                  );
                };
              };
              typos = {
                enable = true;
                configFile = "typos.toml";
              };
              shfmt.enable = true;
              shellcheck.enable = true;
            };
          };

          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              (
                final: prev:
                let
                  inherit (inputs.speedy.packages.${system}) speedy;
                  build = pkgs.writeShellScriptBin "build" ''
                    git clean -xdf ./public
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
                    ${lib.getExe build}
                    speedy run &
                    trap 'jobs -p | xargs kill' EXIT
                    watchexec \
                        --watch posts \
                        --watch static \
                        ${lib.getExe final.speedy} generate
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
                  highlightjs = pkgs.callPackage ./highlightjs.nix { };
                }
              )
            ];
          };
          devShells = {
            default = pkgs.mkShell {
              buildInputs = with pkgs; [
                bashInteractive
                coreutils
                watchexec

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
                [ -d ./static/js/vendor/highlight ] || cp -RL --no-preserve=mode "${pkgs.highlightjs}" ./static/js/vendor/highlight
              '';
            };
            ci = pkgs.mkShell {
              buildInputs = [
                pkgs.bashNonInteractive
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
            with pkgs;
            {
              build = mkApp build;
              serve = mkApp serve;
              icons = mkApp generate-icons;
              default = mkApp serve;
            };

          packages = rec {
            site = pkgs.callPackage ./site.nix { inherit (pkgs) speedy highlightjs; };
            default = site;
          };
        };
    };
}
