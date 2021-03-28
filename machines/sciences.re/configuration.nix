{ ... }: {
  imports = [
    /etc/nixos/hardware-configuration.nix

    ../../users/remy/base.nix
    ../../users/raito/base.nix

    ../../services/ssh.nix
    ../../services/terminfo.nix
    ../../services/sops.nix

    ../../services/opensmtpd.nix
    ../../services/website.nix
    ../../services/keycloak.nix
    ../../services/discourse.nix
    ../../services/mediawiki.nix
  ];

  system.stateVersion = "20.09";

  system.copySystemConfiguration = true;

  boot.cleanTmpDir = true;

  networking.hostName = "sciences.re";
  networking.firewall.allowPing = true;
}
