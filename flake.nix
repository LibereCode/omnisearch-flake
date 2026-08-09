{
  description = ''
    Unofficial nix-flake-wrapper of the
    web meta-search engine **omnisearch**.
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        #NOTE: need testing for other systems
      ];

      perSystem =
        {
          pkgs,
          self',
          ...
        }:
        {
          packages.omnisearch = pkgs.callPackage ./nix/packages/omnisearch.nix { };
          packages.default = self'.packages.omnisearch;

          formatter = pkgs.nixfmt-tree;
        };

      imports = [
        ./nix/modules/test.nix
      ];
      # nixosModules.default = import ./modules { inherit inputs; };
    };
}
