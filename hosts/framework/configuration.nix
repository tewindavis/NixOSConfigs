{ config, lib, ... }:

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

  # No inbound ports at all on the roaming laptop. Syncthing still syncs by
  # dialing out to the other hosts (which keep 22000 open) and via relays; it
  # just can't be dialed *into*, and won't hear LAN discovery broadcasts.
  # Closing mDNS (UDP 5353) also stops `.local` name resolution and CUPS
  # auto-discovery of network printers here — add printers by IP instead.
  services.syncthing.openDefaultPorts = false;
  services.avahi.openFirewall = false;

  # Enforce the above: any module that later opens a port on this host fails
  # evaluation (and `nix flake check`) instead of silently widening it.
  assertions =
    let
      fw = config.networking.firewall;
      ifaceOpen = lib.any (
        i:
        i.allowedTCPPorts != [ ]
        || i.allowedUDPPorts != [ ]
        || i.allowedTCPPortRanges != [ ]
        || i.allowedUDPPortRanges != [ ]
      ) (lib.attrValues fw.interfaces);
    in
    [
      {
        assertion =
          fw.enable
          && fw.allowedTCPPorts == [ ]
          && fw.allowedUDPPorts == [ ]
          && fw.allowedTCPPortRanges == [ ]
          && fw.allowedUDPPortRanges == [ ]
          && !ifaceOpen;
        message = ''
          framework must expose no inbound ports, but the firewall is
          disabled or opens TCP ${toString fw.allowedTCPPorts} / UDP ${toString fw.allowedUDPPorts}
          (or port ranges / per-interface rules). Close it in hosts/framework/configuration.nix.
        '';
      }
    ];
}
