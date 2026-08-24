{ self, inputs, ... }:
{
  perSystem =
    {
      pkgs,
      self',
      inputs',
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit (inputs'.nixpkgs.legacyPackages.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };

      packages = {
        omnisearch = pkgs.callPackage ./omnisearch.nix { };
        default = self'.packages.omnisearch;
      };
    };
}
