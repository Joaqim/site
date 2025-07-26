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

  env.NUXT_TELEMETRY_DISABLED = 1;

  npmDepsHash = "sha256-/tro2cMIrFVKJo0Ds7y+sNTqjKNyrYEM6+zw01kNKjs=";

  postPatch = ''
    mkdir -p public/_fonts
    ln -s ${source-code-pro}/share/fonts/opentype/SourceCodePro-*.otf public/_fonts/
    ln -s ${roboto}/share/fonts/opentype/Roboto-*.otf public/_fonts/
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp -r .output/* $out/

    mkdir $out/bin
    makeWrapper ${lib.getExe nodejs_22} $out/bin/server \
      --append-flags $out/server/index.mjs

    runHook postInstall
  '';

  meta.description = "The source code joaqim.com site";
}
