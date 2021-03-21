{ config, pkgs, lib, ... }:

let
  uploadsRoot = "/run/nginx/uploads";
in
{
  users.users = {
    www = {
      createHome = true;
      useDefaultShell = true;
      home = "/home/www";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKxOacH57XtCyOGzHXidJDSebND2qswa2yLTz/wko7pz actions@github"
      ];
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts."sciences.re" = {
      enableACME = true;
      forceSSL = true;
      root = uploadsRoot;
    };
  };
 
  systemd.services.nginx.serviceConfig.BindReadOnlyPaths = "/home/www/sciences.re:${uploadsRoot}";
 
  security.acme = {
    acceptTerms = true;
    certs = {
      "sciences.re" = {
         email = "contact@sciences.re";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
