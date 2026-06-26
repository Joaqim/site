{
  lib,

  stdenvNoCC,

  speedy,
  highlightjs,
  ...
}:
stdenvNoCC.mkDerivation {
  name = "site";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./LICENSE
      ./posts
      ./static
    ];
  };
  buildInputs = [
    speedy
    highlightjs
  ];
  phases = [
    "unpackPhase"
    "buildPhase"
    "installPhase"
  ];
  buildPhase = ''
    set -euo pipefail

    js_path=./static/public/static/js/vendor
    mkdir -p "$js_path"
    cp -RL --no-preserve=mode "${highlightjs}" "$js_path/highlight"

    speedy generate
  '';
  installPhase = ''
    set -euo pipefail
    mkdir -p $out
    cp -r public $out/
  '';
}
