{ self, inputs, ... }:
{
  perSystem =
    { pkgs, self', ... }:
    {
      packages = {
        omnisearch = pkgs.callPackage ./omnisearch.nix { };
        default = self'.packages.omnisearch;
      };
    };
}
