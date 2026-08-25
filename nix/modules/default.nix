{ inputs, self, ... }:
{
  flake.nixosModules.default =
    per@{
      config,
      lib,
      pkgs,
      self',
      ...
    }:
    let
      cfg = config.services.omnisearch;
      # pkg = pkgs.omnisearch;
      pkg = self'.packages.omnisearch;
      iniType = pkgs.formats.ini.type;
      inherit (lib)
        literalMD
        mkOption
        mkPackageOption
        mkEnableOption
        mkIf
        optionals
        types
        ;
    in
    {

      options.services.omnisearch = {
        enable = mkEnableOption (literalMD "`omnisearch`");

        package = lib.mkPackageOption pkgs "omnisearch" {
          default = pkg;
        };

        settings = mkOption {
          inherit iniType;
          default = { };
          description = literalMD ''
            AttrSet that will be converted into **dosini**-format
            {file}`config.ini`
          '';
        };

        #TODO:
        systemd = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = literalMD "Whether to enable `omnisearch` **systemd-service**.";
          };
          # targets = [];
        };
      };

      config = mkIf cfg.enable {
        # nixpkgs.overlays = [ self'.overlays.default ];

        environment.systemPackages = optionals (cfg.package != null) [
          (cfg.package.overrides { configINIOverrides = cfg.settings; })
        ];

        # A lot of this come from OG omnisearch-systemd-nix-implementation.
        systemd.services.omnisearch =
          let
            srcDir = "${pkg}/share/omnisearch";
            WorkingDirectory = "/var/lib/omnisearch";
          in
          mkIf cfg.systemd.enable {
            description = "Start 'omnisearch' (web meta-search engine) daemon.";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            serviceConfig = {
              ExecStart = "${srcDir}/omnisearch";

              inherit WorkingDirectory;
              StateDirectory = "omnisearch"; # sus?
              CacheDirectory = "omnisearch"; # sus?

              BindReadOnlyPaths = [
                "${srcDir}/templates:${WorkingDirectory}/templates"
                "${srcDir}/static:${WorkingDirectory}/static"
                "${srcDir}/locales:${WorkingDirectory}/locales"
                "${srcDir}/config.ini:${WorkingDirectory}/config.ini"
              ];

              DynamicUser = true;
              ProtectSystem = "strict";
              ProtectHome = true;
              PrivateTmp = true;

              Restart = "always";
              RestartSec = 5;
            };
          };
      };
    };
}
