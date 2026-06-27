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
                generate-static-icons =
                  let
                    convert = "${pkgs.lib.getExe pkgs.imagemagick}";
                  in
                  pkgs.writeShellScriptBin "generate-static-icons" ''
                    # [name]=size
                    declare -A sizes=(
                      [android-chrome-192x192]=192
                      [android-chrome-384x384]=384
                      [apple-touch-icon]=180
                      [favicon-16x16]=16
                      [favicon-32x32]=32
                      [mstile-150x150]=150
                    )

                    # various .png
                    for name in "''${!sizes[@]}"; do
                      ${convert} logo.png -resize "''${sizes[$name]}x''${sizes[$name]}" "./static/''${name}.png"
                    done

                    # favicon.ico
                    ${convert} logo.png -resize 16x16 \
                            \( logo.png -resize 32x32 \) \
                            ./static/favicon.ico
                  '';
                # Adapted from: https://stackoverflow.com/a/76264351
                get-oldest-github-commit-date = pkgs.writeShellApplication {
                  name = "get-oldest-github-commit-date";
                  runtimeInputs = with pkgs; [
                    curlMinimal
                    gawk
                  ];
                  text = ''
                    if [[ -n "$1" ]]; then
                      REPO="$1"
                    else
                      read -rp "Repository (owner/repo): " REPO
                    fi

                    if [[ "''${REPO// }" == "" ]]; then
                      echo "No repository provided."
                      exit 1
                    fi

                    if [[ ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
                      echo "Invalid repository format. Expected: owner/repo"
                      exit 1
                    fi

                    URL="https://api.github.com/repos/$REPO/commits"
                    H=" -H \"Accept: application/vnd.github+json\" \
                      -H \"X-GitHub-Api-Version: 2022-11-28\""

                    response=$(curl -s -L --include "$H" "$URL" | awk 'NR > 1')

                    # Split the output into header and json
                    header=$(echo "$response" | awk 'BEGIN{RS="\r\n";ORS="\r\n"} /^[a-zA-Z0-9-]+:/')
                    commits=$(echo "$response" | awk '!/^[a-zA-Z0-9-]+:/')

                    # If paginated, get last page
                    if [[ $header == *"link"* ]]; then
                      # Extract the last page value
                      link_line=$(echo "$header" | grep -i "^link:")
                      last_page=$(echo "$link_line" | sed -n 's/.*page=\([0-9]\+\)[^0-9].*rel="last".*/\1/p')

                      # Get last-page commits
                      commits=$(curl -s -L "$H" "$URL?page=$last_page")
                    fi

                    # Print first commit
                    commit_date="$(echo "$commits" | jq --raw-output '.[-1].commit.author.date')"
                    echo "''${commit_date%T*}"
                  '';
                };

                # Taken from https://gitlab.com/mplanchard/mplanchard.gitlab.io/-/blob/master/Makefile?ref_type=heads#L63
                create-new-post = pkgs.writeShellScriptBin "create-new-post" ''
                    read -rp "Post Title: " TITLE
                    if [[ "''${TITLE// }" == "" ]]; then
                  		echo -e "No title provided."
                  		exit 1
                  	fi
                  	SLUG=$(echo -n "$TITLE" |
                  		sed --regexp-extended 's/[  ]+/-/g' |
                  		sed 's/[(),.!:]//g' |
                  		awk '{ printf tolower($0) }' |
                  	    jq --slurp --raw-input --raw-output '@uri')  # urlencode
                  	DATE=$(date --iso-8601)
                  	FNAME=$(echo "''${DATE}-''${SLUG}.md")
                  	FPATH=$(echo "posts/''${FNAME}")
                  	if [[ -e "$FPATH" ]]; then
                  		echo "$FPATH" already exists!
                  		exit 1
                  	fi
                    {
                  	  echo "---"
                      echo "draft: true"
                      echo "title: $TITLE"
                      echo "slug: $SLUG"
                      echo "created: $DATE"
                      echo "updated: $DATE"
                      echo "tags:"
                      echo "summary:"
                  	  echo "---"
                    } >> "$FPATH"
                  	echo "Created new post in $FPATH"
                '';
                create-new-project-from-github-repository = pkgs.writeShellScriptBin "create-new-project-from-github-repository" ''
                  if [[ -n "$1" ]]; then
                      REPO="$1"
                  else
                    read -rp "Repository (owner/repo): " REPO
                  fi

                  if [[ "''${REPO// }" == "" ]]; then
                    echo "No repository provided."
                    exit 1
                  fi

                  if [[ ! "$REPO" =~ ^[^/]+/[^/]+$ ]]; then
                    echo "Invalid repository format. Expected: owner/repo"
                    exit 1
                  fi

                  read -rp "Project Title: " TITLE
                  if [[ "''${TITLE// }" == "" ]]; then
                    echo -e "No title provided."
                    exit 1
                  fi

                  REPO_ID="''${REPO#*/}"
                  FNAME=$(echo "$REPO_ID.md")
                  FPATH=$(echo "projects/''${FNAME}")
                  if [[ -e "$FPATH" ]]; then
                    echo "$FPATH" already exists!
                    exit 1
                  fi
                  CREATION_DATE="$(get-oldest-github-commit-date $REPO)"
                  {
                    echo "---"
                    echo "title: $TITLE"
                    echo "id: $REPO_ID"
                    echo "repository: https://github.com/$REPO"
                    echo "license: "
                    echo "created: $CREATION_DATE"
                    echo "status: "
                    echo "---"
                  } >> "$FPATH"
                  echo "Created new project in $FPATH"
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
              create-new-post
              get-oldest-github-commit-date
              create-new-project-from-github-repository
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
            icons = mkApp generate-static-icons;
            default = mkApp serve;
          };

        packages = rec {
          site = callPackage ./site.nix { inherit speedy highlightjs; };
          default = site;
        };
      }
    );
}
