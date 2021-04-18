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
    ../../services/matrix.nix
  ];

  system.stateVersion = "20.09";

  system.copySystemConfiguration = true;

  boot.cleanTmpDir = true;

  networking.hostName = "sciencesre";
  networking.firewall.allowPing = true;
 
  networking.interfaces.ens2.ipv6.addresses = [{
    address = "2001:bc8:62c:2341::1";
    prefixLength = 64;
  }];

  networking.defaultGateway6 = {
    address = "2001:bc8:62c:2341::";
  };


  swapDevices = [ { device = "/var/swap"; size = 2048; } ];

}
