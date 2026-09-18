{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop
    ../../modules/core
    ../../modules/hardware/utm.nix
    ../../modules/services/vpn.nix
    ../../modules/services/syncthing.nix
    ../../users/td/nixos.nix
  ];

  networking.hostName = "utm-nixos";

  # Standard bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # No kernel-cmdline editor at the boot menu. Unlike framework, this guest's
  # root filesystem isn't encrypted, so the editor is the whole barrier:
  # `init=/bin/sh` from the boot menu is root with no passphrase prompt.
  boot.loader.systemd-boot.editor = false;
}
