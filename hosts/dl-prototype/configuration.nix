{ config, lib, pkgs, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix # You'll need to generate this on the machine
      ../../modules/desktop
      ../../modules/core
      ../../modules/hardware/nvidia.nix
      ../../modules/dev/rl-binary.nix
      ../../users/td/nixos.nix
    ];

  # CPU optimizations for Threadripper
  hardware.cpu.amd.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "performance";

  networking.hostName = "dl-prototype";

  # Standard bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.11";
}
