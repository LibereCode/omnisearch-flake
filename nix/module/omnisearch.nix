{ self
, config
, lib
, pkgs
, ...
}:
let
  cfg = config.services.omnisearch;
  inherit (lib)
    types
    mkOption
    mkEnableOption
    mkIf
    ;
  iniFormat = pkgs.formats.ini;
in
{

  options.services.omnisearch = {
    enable = mkEnableOption "omnisearch";

    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.omnisearch;
      description = "omnisearch package to use.";
    };

    settings = mkOption {
      inherit (iniFormat) type;
      default = { };
    };

    #TODO:
    systemd = {
      enable = mkEnableOption "Whether to enable omnisearch systemd-service";
      # targets = [];
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [ self.overlays.default ];
    environment.systemPackages = lib.optionals (cfg.package != null) [ cfg.package ];
  };
}
