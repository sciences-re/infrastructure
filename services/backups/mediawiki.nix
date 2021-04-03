{ config, lib, ... }:
with lib;
let
  parentCfg = config.services.backups;
  restic = parentCfg.package;
  cfg = config.services.backups.mediawiki;
  mediawikiPasswordFile = config.services.mediawiki.passwordFile;
  dbCfg = config.services.mediawiki.database;
in
  {
    options = {
      services.backups.mediawiki = {
        enable = mkOption {
          default = parentCfg.enable;
          type = types.bool;
        };

        startAt = mkOption {
          default = parentCfg.startAt;
          type = types.str;
        };

        repository = mkOption { 
          default = "mediawiki";
          type = types.str;
        };

        passwordFile = mkOption {
          default = parentCfg.passwordFile;
          type = types.str;
        };
      }
    };

    config = mkIf cfg.enable {
      systemd.services.mediawiki-backup = {
        after = [ "mediawiki.service" ];
        startAt = cfg.startAt;
        environment = {
          RESTIC_REPOSITORY = cfg.repository;
          RESTIC_PASSWORD_FILE = cfg.passwordFile;
        };
        description = [ "Backup Mediawiki data through Restic" ];
        # TODO(Ryan): handle restart of this service.
        script = ''
          #${pkgs.stdenv.shell}
          set -o pipefail
          export MYSQL_PWD=$(cat ${mediawikiPasswordFile})
          ${pkgs.mysqldump}/bin/mysqldump -h ${dbCfg.host} -u ${dbCfg.user} -p ${dbCfg.name} | ${restic} backup --tag mediawiki --tag db --stdin --stdin-filename mediawiki-db.sql
          # TODO(Ryan): Take a wiki dump too.
        '';
      };
      # TODO(Ryan): script to restore an old backup using restic.
    };
  }
