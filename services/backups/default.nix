{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.services.backups;
  resticOpts = {
    options = {
      extraArgs = mkOption {
        description = ''Extra arguments to pass to restic
          If this is modified, pay attention to restic behavior to find the rclone configuration path.
          Otherwise, pass it yourself.
        '';
        type = types.str;
        default = "-o rclone.args=\"serve restic --stdio --b2-hard-delete --config ${cfg.rclone.configFile}\"";
      };
    };
  };
  rcloneOpts = {
    options = {
      s3AccessKeyIdFile = mkOption {
        description = "Filename to S3 Access Key ID";
        type = types.str;
        default = "/run/secrets/s3_access_key_id";
      };
      s3SecretKeyIdFile = mkOption {
        description = "Filename to S3 Secret Key ID";
        type = types.str;
        default = "/run/secrets/s3_secret_key_id";
      };

      s3Endpoint = mkOption {
        description = "S3 Endpoint, default to Scaleway Object Storage in Paris";a
        default = "s3.fr-par.scw.cloud";
        type = types.str;
      };

      s3Region = mkOption {
        description = "S3 Region, default to Paris";
        default = "fr-par";
        type = types.str;
      };

      s3ACL = mkOption {
        description = "S3 ACL, default to private";
        default = "private";
        type = types.str;
      };

      configFile = mkOption {
        description = "Config filename, put it in a private path as secrets are written there";
        default = "/run/secrets/rclone_config";
        type = types.str;
      };

      remote = mkOption {
        description = "Remote name for rclone, default to `backups`";
        default = "backups";
        type = types.str;
      };
    };
  };
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
      bucket = mkOption {
        description = "Bucket name in Scaleway Object Storage";
        type = types.str;
      };

      restic = mkOption {
        description = "restic-specific configuration";
        type = types.submodule resticOpts;
      };

      rclone = mkOption {
        description = "rclone-specific configuration";
        type = types.submodule rcloneOpts;
      };
    };
  };

  config = mkIf cfg.enable {
    # TODO(Ryan): Script to automatically mount the buckets.
    environment.systemPackages = [ cfg.package ];

    systemd.services.init-rclone-remotes = {
      script = ''
        export S3_ACCESS_KEY_ID=$(cat ${cfg.s3AccessKeyIdFile})
        export S3_SECRET_KEY_ID=$(cat ${cfg.s3SecretKeyIdFile})
        cat > ${cfg.rclone.configFile} <<EOF
        [${cfg.rclone.remote}]
        type = s3
        provider = Scaleway
        env_auth = false
        access_key_id = $S3_ACCESS_KEY_ID
        secret_access_key = $S3_SECRET_KEY_ID
        endpoint = ${cfg.rclone.s3Endpoint}
        acl = ${cfg.rclone.s3ACL}
        region = ${cfg.rclone.s3Region}
        EOF
      '';
    };
  };
}

