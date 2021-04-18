{ pkgs, lib, config, ... }:
let
  matrixDatabasePasswordFile = "/run/secrets/matrix_database_password";
  matrixOidcConfigFile = "/run/secrets/matrix_oidc_config";
  fqdn = "sciences.re";
  element = "chat.sciences.re";
in
{
  sops.secrets.matrix_database_password = {
    format = "yaml";
    key = "matrix_database_password";
    mode = "0440";
    owner = "postgres";
    group = "users";
  };

  users.users.postgres.extraGroups = [ config.users.groups.keys.name ];
  
  sops.secrets.matrix_oidc_config = {
    format = "yaml";
    key = "matrix_oidc_config";
    mode = "0440";
    owner = "matrix-synapse";
    group = "users";
  };
  
  users.users.matrix-synapse.extraGroups = [ config.users.groups.keys.name ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.postgresql.enable = true;
  services.postgresql.initialScript = pkgs.writeText "synapse-init.sql" ''
    \set  password `cat ${matrixDatabasePasswordFile}`;
    CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD :'password';
    CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
      TEMPLATE template0
      LC_COLLATE = "C"
      LC_CTYPE = "C";
  '';

  services.nginx = {
    enable = true;
    # only recommendedProxySettings and recommendedGzipSettings are strictly required,
    # but the rest make sense as well
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts = {
      # This host section can be placed on a different host than the rest,
      # i.e. to delegate from the host being accessible as ${config.networking.domain}
      # to another host actually running the Matrix homeserver.
      "${fqdn}" = {
        locations."= /.well-known/matrix/server".extraConfig =
          let
            # use 443 instead of the default 8448 port to unite
            # the client-server and server-server port for simplicity
            server = { "m.server" = "${fqdn}:443"; };
          in ''
            add_header Cache-Control public;
            add_header Content-Type application/json;
            return 200 '${builtins.toJSON server}';
          '';
        locations."= /.well-known/matrix/client".extraConfig =
          let
            client = {
              "m.homeserver" =  { "base_url" = "https://${fqdn}"; };
              "m.identity_server" =  { "base_url" = null; };
              "integrations_ui_url" = "";
              "integrations_rest_url" = "";
              "integrations_widgets_urls" = "";
              "disable_3pid_login" = true;
              "id_server" = "";
              "disable_guests" = false;
              "m.integrations" = {
                  "managers" = [];
              };
            };
          # ACAO required to allow element-web on any URL to request this json file
          in ''
            add_header Content-Type application/json;
            add_header Access-Control-Allow-Origin *;
            add_header Cache-Control public;
            return 200 '${builtins.toJSON client}';
          '';
        
        # forward all Matrix API calls to the synapse Matrix homeserver
        locations."/_matrix" = {
          proxyPass = "http://[::1]:8008"; # without a trailing /
        };
        locations."/_synapse/client" = {
          proxyPass = "http://[::1]:8008"; # without a trailing /
        };
        locations."/_synapse/oidc/callback" = {
          proxyPass = "http://[::1]:8008"; # without a trailing /
        };

       };

      "${element}" = {
          enableACME = true;
          forceSSL = true;
          root = pkgs.element-web.override {
            conf = {
              default_server_config."m.homeserver" = {
                "base_url" = "https://${fqdn}";
                "server_name" = "${fqdn}";
              };
              default_server_config."m.identity_server" = {
                "base_url" = "";
              };
              "m.identity_server" =  { "base_url" = null; };
              "integrations_ui_url" = null;
              "integrations_rest_url" = null;
              "integrations_widgets_urls" = null;
              "disable_3pid_login" = true;
              "id_server" = "";
              "disable_guests" = false;
              "defaultCountryCode" = "FR";
              "brand" = "Chat Sciences.Re";
              "roomDirectory" = lib.mkForce {};
              "permalinkPrefix" = "https://${element}";
              "enable_presence_by_hs_url" = lib.mkForce {};
              "disable_custom_urls" = true;
              "m.integrations" = {
                  "managers" = [];
              };
              "features" = {
                  "feature_latex_maths" = true;
                  "feature_new_spinner" = true;
              };
              "settingDefaults" = {
                  "UIFeature.thirdPartyId" = false;
                  "UIFeature.identityServer" = false;
                  "UIFeature.widgets" = false;
                  "UIFeature.feedback" = false;
                  "UIFeature.registration" = false;
                  "UIFeature.passwordReset" = false;
                  "UIFeature.deactivate" = false;
                  "UIFeature.advancedEncryption" = false; 
              };
           };
         };
      };
    };
  };
  services.matrix-synapse = {
    enable = true;
    server_name = "${fqdn}";
    url_preview_enabled = true;
    allow_guest_access = true;
    public_baseurl = "https://${fqdn}/";
    listeners = [
      {
        port = 8008;
        bind_address = "::1";
        type = "http";
        tls = false;
        x_forwarded = true;
        resources = [
          {
            names = [ "client" "federation" ];
            compress = false;
          }
        ];
      }
    ];
    extraConfigFiles = [
      matrixOidcConfigFile
    ];

    extraConfig = ''
password_config:
    enabled: false
    localdb_enabled: false
allow_public_rooms_without_auth: true
allow_public_rooms_over_federation: false

sso:
   client_whitelist:
     - https://${element}/
'';
  };

  security.acme.email = "contact@sciences.re";
}
