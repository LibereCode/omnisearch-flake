{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , flake-parts
    , ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        #NOTE: need testing for other systems
      ];

      perSystem =
        { pkgs, self', ... }:
        {
          packages.omnisearch = pkgs.callPackage ./nix/pkgs/omnisearch.nix { };
          packages.default = self'.packages.omnisearch;

          formatter = pkgs.nixpkgs-fmt;
        };

      flake.overlays = { self', ... }: {
        default = final: prev: {
          omnisearch = self'.packages.default;
        };
      };

      flake.nixosModules.default = import ./nix/module/omnisearch.nix;
    };
}
