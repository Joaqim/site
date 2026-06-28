# site

Created by extending in-line Rust HTML, CSS and Javascript generator `speedy` as found in [gitlab.com/mplanchard/mplanchard.gitlab.io](https://gitlab.com/mplanchard/mplanchard.gitlab.io) which I forked as a stand-alone nix flake repository with some changes: [https://gitlab.com/Joaqim/speedy](gitlab.com/Joaqim/speedy).

Generated blog can be found at [https://blog.joaqim.com](blog.joaqim.com).

Some limitations: For changes to `./templates` to apply to `speedy generate`, we require a full rebuild of `speedy` (see derivation in `flake.nix`.)

This happens intermittently on `direnv reload`, where `speedy` is imported to default dev shell and is only used indirectly by script utilities such `nix run .#build` and `nix run .#serve`.
