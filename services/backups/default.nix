{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.backups;
in
{
  imports = [ ./mediawiki.nix ]; # TODO(Ryan): keycloak.nix
  options = {
    services.backups = {
      enable = mkEnableOption "Enable automatic backups";
      package = mkOption {
        description = "Restic package to use for backups";
        default = pkgs.restic;
        defaultText = "pkgs.restic";
        type = types.package;
      };
      passwordFile = mkOption {
        description = "Password file to encrypt / decrypt backups";
        type = types.str;
      };
      startAt = mkOption {
        description = "OnCalendar entry for systemd timers for backup units";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    # TODO(Ryan): Script to automatically mount the buckets.
    environment.systemPackages = [ cfg.package ];
  };
}

