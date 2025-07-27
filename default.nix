{
  lib,
  buildNpmPackage,
  node-gyp,
  openssl,
  nodejs_22,
  pkg-config,
  python3,
  vips,
  source-code-pro,
  roboto,
}:
let
  src = lib.cleanSourceWith {
    src = ./.;
    filter =
      path: _type:
      (lib.hasSuffix "\.json" path)
      || (lib.hasSuffix "\.ts" path)
      || (lib.hasInfix "/app/" path)
      || (lib.hasInfix "/content/" path)
      || (lib.hasInfix "/public/" path);
  };
in
buildNpmPackage {
  pname = "joaqim-site";
  version = "0-unstable-2025-07-26";

  inherit src;

  nativeBuildInputs = [
    nodejs_22
    node-gyp
    pkg-config
    python3
  ];

  buildInputs = [
    openssl
    vips
  ];

  env = {
    NUXT_TELEMETRY_DISABLED = 1;
    NUXT_APP_BASE_URL = "/site/";
    NUXT_PUBLIC_API_BASE = "https://joaqim.github.io";
  };

  npmDepsHash = "sha256-/tro2cMIrFVKJo0Ds7y+sNTqjKNyrYEM6+zw01kNKjs=";

  npmBuildScript = "generate";

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp -r .output/* $out/

    runHook postInstall
  '';

  meta.description = "The source code joaqim.com site";
}
