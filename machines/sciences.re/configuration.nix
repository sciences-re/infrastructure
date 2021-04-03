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

    ../../services/backups
  ];

  system.stateVersion = "20.09";

  system.copySystemConfiguration = true;

  boot.cleanTmpDir = true;

  networking.hostName = "sciences.re";
  networking.firewall.allowPing = true;
 
  networking.interfaces.ens2.ipv6.addresses = [{
    address = "2001:bc8:47b0:2640::1";
    prefixLength = 64;
  }];

  networking.defaultGateway6 = {
    address = "2001:bc8:47b0:2640::";
  };

  services.backups.enable = true;
  services.backups.mediawiki.enable = false; # For now, we have to create the repository and prepare for rclone setup.

  swapDevices = [ { device = "/var/swap"; size = 2048; } ];

}
