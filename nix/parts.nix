{ self, inputs, ... }:
{
  imports = [
    ./experiments
    ./packages
    ./modules
  ];

  systems = [
    "x86_64-linux"
    #NOTE: need testing for other systems
  ];

  perSystem =
    {
      pkgs,
      ...
    }:
    {
      formatter = pkgs.nixfmt-tree;
    };

  #TODO:
  # nixosModules.default = import ./modules { inherit inputs; };
}
