{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> {};
in
{
  documentation.nixos.enable = false;
  imports = [ <nixos-unstable/nixos/modules/services/web-apps/keycloak.nix> ];

  sops.secrets.database_password = {
    format = "yaml";
    key = "database_password";
    mode = "0440";
    owner = "postgres";
    group = "postgres";
  };

  systemd.services.keycloakPostgreSQLInit = {
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };

  systemd.services.keycloak.serviceConfig = {
    BindReadOnlyPaths = "/etc/nixos/static/keycloak-sciences-re-theme.jar:/run/keycloak/deployments/keycloak-sciences-re-theme.jar";
    MemoryAccounting = true;
    MemoryMax = "512M";
  };

  services.keycloak = {
    package = unstable.keycloak;
    enable = true;
    databasePasswordFile = "/run/secrets/database_password";
    frontendUrl = "https://auth.sciences.re/auth/";
    forceBackendUrlToFrontendUrl = true;
    initialAdminPassword = "toto";
    httpPort = "8080";
    extraConfig = {
      "subsystem=undertow"."server=default-server"."http-listener=default".proxy-address-forwarding = true;
      "subsystem=keycloak-server"."theme=defaults".welcomeTheme="logo-example";
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts."auth.sciences.re" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
      };
    };
  };

  security.acme = {
    acceptTerms = true;
    certs = {
      "auth.sciences.re" = {
         email = "contact@sciences.re";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

}
