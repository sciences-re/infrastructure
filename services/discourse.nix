{config, lib, pkgs, ...}:


let s3SecretKeyIdFile = "/run/secrets/s3_secret_key_id";
    s3AccessKeyIdFile = "/run/secrets/s3_access_key_id";
    s3Endpoint = "https://s3.fr-par.scw.cloud";
    s3Region = "fr-par";
    s3BackupBucket = "sciences-re-backups";
in
{
  options = {
    nullable.services.discourse = {
      hostname = lib.mkOption {
        type = lib.types.str;
      };

      config = lib.mkOption {
        type = lib.types.str;
        
        default =
          ''
            env:
              UNICORN_WORKERS: 1
              DISCOURSE_DEVELOPER_EMAILS: remy@grunblatt.org
              DISCOURSE_HOSTNAME: "${config.nullable.services.discourse.hostname}"
              DISCOURSE_SMTP_ADDRESS: 172.17.0.1
              DISCOURSE_SMTP_PORT: 25
              LANG: en_US.UTF-8
              UNICORN_WORKERS: 2
              DISCOURSE_USE_S3: true
              DISCOURSE_S3_REGION: "${s3Region}"
              DISCOURSE_S3_ENDPOINT: "${s3Endpoint}"
              DISCOURSE_S3_ACCESS_KEY_ID: S3_ACCESS_KEY_ID_REPLACE_ME
              DISCOURSE_S3_SECRET_ACCESS_KEY: S3_SECRET_ACCESS_KEY_REPLACE_ME
              DISCOURSE_S3_BACKUP_BUCKET: "${s3BackupBucket}"
              DISCOURSE_BACKUP_LOCATION: s3
            hooks: 
              after_code: 
                - 
                  exec: 
                    cd: $home/plugins
                    cmd: 
                      - "git clone https://github.com/discourse/docker_manager.git"
                      - "git clone https://github.com/discourse/discourse-openid-connect.git"
                      - "git clone https://github.com/discourse/discourse-math.git"
                      - "git clone https://github.com/discourse/discourse-spoiler-alert"
                      - "git clone https://github.com/discourse/discourse-solved.git"
            params: 
              db_shared_buffers: "512MB"
              db_default_text_search_config: pg_catalog.english
            run: 
              - exec: "echo \"Beginning of custom commands\""
              - exec: "echo \"End of custom commands\""
            templates: 
              - templates/postgres.template.yml
              - templates/redis.template.yml
              - templates/web.template.yml
              - templates/web.ratelimited.template.yml
              - templates/web.socketed.template.yml
            volumes: 
              - 
                volume: 
                  guest: /shared
                  host: "/var/discourse/shared/standalone"
              - 
                volume: 
                  guest: /var/log
                  host: "/var/discourse/shared/standalone/log/var-log"
          '';
      };
    };
  };

  config = {

    nullable.services.discourse.hostname = "forum.sciences.re";


    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };

    environment.systemPackages = [ pkgs.git ];
    systemd.services.discourse-setup = {
      wants = [ "docker.service" ];
      after = [ "network.target" "docker.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.git pkgs.bash pkgs.nettools pkgs.which pkgs.gawk pkgs.docker ];
      script =
      ''
        if [[ ! -e /var/discourse ]]; then
          git clone https://github.com/discourse/discourse_docker.git /var/discourse
        fi
        cp ${pkgs.writeText "discourse-app.yml" config.nullable.services.discourse.config} /var/discourse/containers/app.yml
        sed -i "s/S3_ACCESS_KEY_ID_REPLACE_ME/$(cat ${s3AccessKeyIdFile})/" /var/discourse/containers/app.yml
        sed -i "s/S3_SECRET_ACCESS_KEY_REPLACE_ME/$(cat ${s3SecretKeyIdFile})/" /var/discourse/containers/app.yml
        cd /var/discourse
        git pull
        bash ./launcher rebuild app
      '';
      serviceConfig = {
        Type = "simple";
        RemainAfterExit = "yes";
      };
    };

    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts."forum.sciences.re" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://unix:/var/discourse/shared/standalone/nginx.http.sock";
        };
      };
    };

    security.acme = {
      acceptTerms = true;
      certs = {
        "forum.sciences.re" = {
           email = "contact@sciences.re";
        };
      };
    };

  };
}
