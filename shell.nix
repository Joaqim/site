{
  mkShellNoCC,
  nodejs_22,
  # extra tooling
  eslint_d,
  prettierd,
  typescript,
  nodePackages,
  vips,
  callPackage,
}:
let
  # Just to provide dependencies in shell, actual development
  # is done by using preferred node package manager
  defaultPackage = callPackage ./default.nix { };
in
mkShellNoCC {
  inputsFrom = [ defaultPackage ];

  packages = [
    nodejs_22

    # Automatically use the right package manager, npm, yarn, pnpm, etc...
    nodePackages."@antfu/ni"
    eslint_d
    prettierd
    typescript
    vips
  ];

  NUXT_TELEMETRY_DISABLED = 1;

  shellHook = ''
    eslint_d start # start eslint daemon
    eslint_d status # inform user about eslint daemon status

    echo "Type 'ni install' to install dependencies"
    echo "Type 'ni preview' to start the preview server"
    echo "Type 'ni generate' to build the static files"
    echo "Type 'ni dev' to start the development server"
  '';
}
