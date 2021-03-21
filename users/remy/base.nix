{ config, pkgs, lib, ... }: {

  users.users = {
    remy = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILjfNIqw1xgnIc9CaBfxhZtIEu7F/sfNENip9Ou5KZm9 remy@sauron"
      ];
    };
  };
}
