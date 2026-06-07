{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ../../modules/desktop
      ../../modules/core
      ../../modules/hardware/utm.nix
      ../../modules/services/vpn.nix
      ../../users/td/nixos.nix
    ];

  networking.hostName = "utm-nixos";

  # Standard bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.11";
}
