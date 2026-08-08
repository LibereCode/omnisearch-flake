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
          packages.omnisearch = pkgs.callPackage ./pkgs/omnisearch.nix { };
          packages.default = self'.packages.omnisearch;

          formatter = pkgs.nixpkgs-fmt;
        };

      flake.overlays = { self', ... }: {
        default = final: prev: {
          omnisearch = self'.packages.default;
        };
      };

      flake.nixosModules.default =
        { config
        , lib
        , pkgs
        , ...
        }:
        let
          cfg = config.services.omnisearch;
          inherit (lib) types;
        in
        {
          nixpkgs.overlays = [ self.overlays.default ];
          options.services.omnisearch = {
            enable = lib.mkEnableOption "omnisearch";

            package = lib.mkOption {
              type = types.nullOr types.package;
              default = pkgs.omnisearch;
              description = "omnisearch package to use.";
            };

            #TODO:
            systemd = {
              enable = lib.mkEnableOption "Whether to enable omnisearch systemd-service";
              # targets = [];
            };
          };

          config = lib.mkIf cfg.enable {
            environment.systemPackages = lib.optionals (cfg.package != null) [ cfg.package ];
          };
        };
    };
}
