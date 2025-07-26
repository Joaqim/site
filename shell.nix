{
  mkShellNoCC,
  nodejs_22,
  # extra tooling
  eslint_d,
  prettierd,
  typescript,
  nodePackages,

  callPackage,
}:
let
  defaultPackage = callPackage ./default.nix { };
in
mkShellNoCC {
  inputsFrom = [ defaultPackage ];

  packages = [
    nodejs_22
    nodePackages."@antfu/ni" # Automatically use the right package manager, npm, yarn, pnpm...
    eslint_d
    prettierd
    typescript
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
