{
  description = "Development environment for Nuxt.js project with Node.js and TypeScript";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
          system: function nixpkgs.legacyPackages.${system}
        );
    in
    {
      packages = forAllSystems (pkgs: {
        joaqim-site = pkgs.callPackage ./default.nix { };
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.joaqim-site;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.callPackage ./shell.nix { };
      });

      overlays.default = final: _: { joaqim-site = final.callPackage ./default.nix { }; };
    };
}
