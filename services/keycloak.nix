{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> {};
in
{
  documentation.nixos.enable = false;
  imports = [ <nixos-unstable/nixos/modules/services/web-apps/keycloak.nix> ];

  services.keycloak = {
    package = unstable.keycloak;
    enable = true;
    databasePasswordFile = "/etc/nixos/secrets/keycloak/db_password";
    frontendUrl = "https://auth.sciences.re/auth";
    initialAdminPassword = "${lib.fileContents ../secrets/keycloak/initial_admin_password}";
    httpPort = "8080";
  };

  services.nginx = {
    enable = true;
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
