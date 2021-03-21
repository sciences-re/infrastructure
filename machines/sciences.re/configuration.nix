{ ... }: {
  imports = [
    /etc/nixos/hardware-configuration.nix
    ../../users/remy/base.nix
    ../../users/raito/base.nix
    ../../services/ssh.nix
    ../../services/terminfo.nix
  ];

  boot.cleanTmpDir = true;

  networking.hostName = "sciences.re";
  networking.firewall.allowPing = true;
}
