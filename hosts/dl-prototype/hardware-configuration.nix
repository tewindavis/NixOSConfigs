# PLACEHOLDER — dl-prototype has not been provisioned yet.
#
# This stub exists only so `nixosConfigurations.dl-prototype` evaluates
# (required for `nix flake check` / CI to pass on the other two hosts too,
# since flake checking evaluates every entry in nixosConfigurations).
#
# Before deploying to the real machine, replace this file with the actual
# output of `nixos-generate-config` run on that machine.
{ lib, ... }:

{
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000";
    fsType = "ext4";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
