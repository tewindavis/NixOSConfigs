{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ../../modules/desktop
      ../../modules/core
      ../../modules/hardware/framework.nix
      ../../modules/services/vpn.nix
      ../../users/td/nixos.nix
    ];

  networking.hostName = "framework";

  # Enable touchpad support for the laptop
  services.libinput.enable = true;

  # Standard bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.11";
}
