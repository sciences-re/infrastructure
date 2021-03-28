{ config, pkgs, lib, ... }:
{
  sops.secrets.email_password = {
    format = "yaml";
    key = "email_password";
    mode = "0440";
    owner = "smtpd";
    group = "smtpd";
  };

  users.users.smtpd.extraGroups = [ config.users.groups.keys.name ];

  services.opensmtpd = {
    enable = true;
    serverConfiguration = ''
      table secrets file:/run/secrets/email_password
      listen on lo
      listen on docker0
      action "relay-rewrite-from" relay helo sciences.re host smtp+tls://contact@mail.gandi.net:587 auth <secrets> mail-from contact@sciences.re
      action "relay" relay helo sciences.re host smtp+tls://contact@mail.gandi.net:587 auth <secrets>
      match for any from any !mail-from "@sciences.re" action "relay-rewrite-from"
      match for any from any mail-from "@sciences.re" action "relay"
      '';
  };
  environment.systemPackages = [ pkgs.opensmtpd ];
}
