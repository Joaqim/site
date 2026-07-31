{ stdenvNoCC, fetchurl, ... }:
stdenvNoCC.mkDerivation rec {
  name = "highlight-gruvbox-pale";
  version = "11.11.1";

  srcs = [
    (fetchurl {
      url = "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@${version}/build/highlight.min.js";
      hash = "sha256-xKOZ3W9Ii8l6NUbjR2dHs+cUyZxXuUcxVMb7jSWbk4E=";
    })
    (fetchurl {
      url = "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@${version}/build/languages/nix.min.js";
      hash = "sha256-j4dmtrr8qUODoICuOsgnj1ojTAmxbKe00mE5sfElC/I=";
    })
    (fetchurl {
      url = "https://cdn.jsdelivr.net/gh/highlightjs/cdn-release@${version}/build/styles/base16/gruvbox-dark-pale.min.css";
      hash = "sha256-2D8yseRyYPFPoRAX4ZnELXQKw27MT01QAjE9mxHW25g=";
    })
  ];
  dontBuild = true;
  dontCheck = true;

  unpackPhase = ''
    runHook preUnpack

    mkdir "$out"
    for _src in $srcs; do
      cp "$_src" $(stripHash "$_src")
    done

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    path="$out"

    # vendored javascript
    mkdir -p "$path"
    cp -RL --no-preserve=mode highlight.min.js "$path"

    # languages
    languages_path="$path/languages/"
    mkdir -p "$languages_path"
    cp -RL --no-preserve=mode nix.min.js "$languages_path"

    # vendored CSS
    css_path="$path/styles/base16"
    mkdir -p "$css_path"
    cp -RL --no-preserve=mode *.css "$css_path"

    runHook postInstall
  '';
}
