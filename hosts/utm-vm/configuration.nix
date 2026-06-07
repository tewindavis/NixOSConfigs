{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ../../modules/desktop
      ../../modules/core
      ../../modules/hardware/utm.nix
      ../../users/td/nixos.nix
    ];

  networking.hostName = "utm-nixos";

  # Standard bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.11";
}
