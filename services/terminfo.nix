{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    kitty.terminfo
    alacritty.terminfo
  ];
}
