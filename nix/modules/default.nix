{ inputs, self, ... }:
{
  flake.nixosModules.default =
    per@{
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.omnisearch;
      # pkg = pkgs.omnisearch;
      pkg = self.packages.${pkgs.stdenv.hostPlatform.system}.omnisearch;
      default_user = "omnisearch";
      inherit (lib)
        literalMD
        mkOption
        mkEnableOption
        mkIf
        types
        ;
    in
    {

      options.services.omnisearch = {
        enable = mkEnableOption (literalMD "`omnisearch`");

        package = mkOption {
          type = types.package;
          default = pkg;
          description = literalMD "`omnisearch` **package** to use.";
        };

        settings = mkOption {
          type = pkgs.formats.ini.type;
          default = { };
          description = literalMD ''
            AttrSet that will be converted into **dosini**-format
            {file}`config.ini`
          '';
        };

        dataDir = mkOption {
          type = types.path;
          default = "/var/lib/" + cfg.user;
          example = "/tmp/weird/place";
          description = ''
            The working and home directory of the user.
          '';
        };

        user = mkOption {
          type = types.str;
          default = default_user;
          example = "LimitedQuery";
          description = ''
            The user to run omnisearch as.
            Will also control which is the WorkingDirectory

            By default a user named `${default_user}` will be created.
          '';
        };
        group = mkOption {
          type = types.str;
          default = cfg.user;
          example = "sysSquad";
          description = ''
            The group to run omnisearch under.

            By default a group matching user will be created.
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

        environment.systemPackages = [
          # (cfg.package.override { configINIOverrides = cfg.settings; })
          cfg.package
        ];

        users = {
          users.${cfg.user} = {
            isSystemUser = true;
            group = cfg.group;
            home = cfg.dataDir;
            createHome = true;
            description = "omnisearch user";
          };
          groups.${cfg.group} = {
          };
        };

        systemd.services.omnisearch =
          let
            srcDir = "${pkg}/share/omnisearch";
          in
          mkIf cfg.systemd.enable {
            description = "Omnisearch Web Search Server";
            wantedBy = [ "multi-user.target" ];
            after = [ "network.target" ];
            serviceConfig = {
              User = cfg.user;
              Group = cfg.group;

              ExecStart = "${srcDir}/omnisearch";

              WorkingDirectory = cfg.dataDir;
              StateDirectory = "omnisearch"; # sus?
              CacheDirectory = "omnisearch"; # sus?

              BindReadOnlyPaths = [
                "${srcDir}/templates:${cfg.dataDir}/templates"
                "${srcDir}/static:${cfg.dataDir}/static"
                "${srcDir}/locales:${cfg.dataDir}/locales"
                "${srcDir}/config.ini:${cfg.dataDir}/config.ini"
              ];

              DynamicUser = true;
              ProtectSystem = "strict";
              ProtectHome = true;
              # PrivateTmp = true;
              # NoNewPrivileges = true;

              Restart = "always";
              RestartSec = 5;
            };
          };
      };
    };
}
