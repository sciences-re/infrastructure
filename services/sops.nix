{ config, pkgs, lib, ... }:

{
  imports = [
    <sops-nix/modules/sops>
  ];

  sops.defaultSopsFile = ./../secrets.yaml;

  system.activationScripts.secrets-permissions = ''
    chmod o+x /run/secrets /run/secrets.d
  '';

}
