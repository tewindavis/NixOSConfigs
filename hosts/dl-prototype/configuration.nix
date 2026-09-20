{ ... }:

{
  imports = [
    ./hardware-configuration.nix # You'll need to generate this on the machine
    ../../modules/desktop
    ../../modules/core
    ../../modules/hardware/nvidia.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/services/vpn.nix
    ../../modules/services/syncthing.nix
    ../../modules/services/training-metrics.nix
    ../../modules/services/liftoff-telemetry.nix
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
  # No kernel-cmdline editor at the boot menu. Unlike framework, this host's
  # root filesystem isn't encrypted, so the editor is the whole barrier:
  # `init=/bin/sh` from the boot menu is root with no passphrase prompt.
  boot.loader.systemd-boot.editor = false;
  # Keep the boot menu to the 15 most recent generations. Without this every
  # switch adds an entry (43 had accumulated on framework) and each one keeps
  # its kernel and initrd on the 1GB ESP. Older generations stay in the Nix
  # store and come back on the next `nixos-rebuild boot`; only their menu
  # entries and kernels are dropped.
  boot.loader.systemd-boot.configurationLimit = 15;
}
