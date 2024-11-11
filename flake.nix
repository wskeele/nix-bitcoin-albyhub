{
  description = "Albyhub extension for nix-bitcoin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
      ];
      allSystems = (
        function: nixpkgs.lib.genAttrs
          systems
          (system: function {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          })
      );
      mkAlbyhub = pkgs: pkgs.callPackage ./pkgs/albyhub.nix { };
    in
    {
      packages = allSystems
        ({ pkgs, system }: rec {
          albyhub = mkAlbyhub pkgs;
          default = default;
        });
    };
}
