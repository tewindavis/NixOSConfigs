{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop
    ../../modules/core
    ../../modules/hardware/framework.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/services/vpn.nix
    ../../modules/services/syncthing.nix
    ../../users/td/nixos.nix
  ];

  networking.hostName = "framework";

  # Enable touchpad support for the laptop
  services.libinput.enable = true;

  # Standard bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # No kernel-cmdline editor at the boot menu: it otherwise lets anyone with
  # physical access boot `init=/bin/sh`. LUKS (see hardware-configuration.nix)
  # still guards the data here, but this closes the tamper path itself.
  boot.loader.systemd-boot.editor = false;

  # Nothing SSHes into the laptop (the only accepted login in the 30 days
  # before this change was a localhost test), and it is the host that roams
  # onto untrusted LANs. sshd keeps running key-only from modules/core, so
  # `ssh localhost` and outbound ssh are unaffected; only port 22 closes.
  # dl-prototype and utm-vm keep it open for remote access.
  services.openssh.openFirewall = false;
}
