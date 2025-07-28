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
  # Configuration options
  enableServer ? false, # Set to true for server deployment, false for static generation
  baseUrl ? if enableServer then "/" else "/site/",
  apiBase ? if enableServer then "http://localhost:3000" else "https://joaqim.github.io",
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
  version = "0-unstable-2025-07-28";

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

  env =
    {
      NUXT_TELEMETRY_DISABLED = 1;
    }
    // lib.optionalAttrs (!enableServer) {
      # Static generation specific environment variables
      NUXT_APP_BASE_URL = baseUrl;
      NUXT_PUBLIC_API_BASE = apiBase;
    };

  npmDepsHash = "sha256-/tro2cMIrFVKJo0Ds7y+sNTqjKNyrYEM6+zw01kNKjs=";

  # Use generate for static sites, default build for server
  npmBuildScript = if enableServer then "build" else "generate";

  postPatch = lib.optionalString enableServer ''
    mkdir -p public
    ln -s ${source-code-pro}/share/fonts/opentype/SourceCodePro-*.otf public/
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp -r .output/* $out/

    ${lib.optionalString enableServer ''
      # Create server wrapper for server deployment
      mkdir $out/bin
      makeWrapper ${lib.getExe nodejs_22} $out/bin/server \
        --append-flags $out/server/index.mjs
    ''}

    runHook postInstall
  '';

  meta = {
    description = "The source code for https://joaqim.github.io/site - ${
      if enableServer then "server deployment" else "static generation"
    }";
    homepage = "https://github.com/Joaqim/site";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ ];
  };
}
