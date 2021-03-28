{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    alacritty.terminfo
  ];
}
