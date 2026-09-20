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
  # Keep the boot menu to the 15 most recent generations. Without this every
  # switch adds an entry (43 had accumulated on framework) and each one keeps
  # its kernel and initrd on the 1GB ESP. Older generations stay in the Nix
  # store and come back on the next `nixos-rebuild boot`; only their menu
  # entries and kernels are dropped.
  boot.loader.systemd-boot.configurationLimit = 15;

  # Nothing SSHes into the laptop (the only accepted login in the 30 days
  # before this change was a localhost test), and it is the host that roams
  # onto untrusted LANs. sshd keeps running key-only from modules/core, so
  # `ssh localhost` and outbound ssh are unaffected; only port 22 closes.
  # dl-prototype and utm-vm keep it open for remote access.
  services.openssh.openFirewall = false;
  # And don't listen off-host at all, so the firewall isn't the only layer.
  # Not `openssh.enable = false`: sops-nix decrypts with sshd's host key
  # (modules/core/secrets.nix), whose generation is tied to the service.
  services.openssh.listenAddresses = [
    {
      addr = "127.0.0.1";
      port = 22;
    }
    {
      addr = "[::1]";
      port = 22;
    }
  ];

  # No inbound ports at all on the roaming laptop. Syncthing still syncs by
  # dialing out to the other hosts (which keep 22000 open) and via relays; it
  # just can't be dialed *into*, and won't hear LAN discovery broadcasts.
  # Closing mDNS (UDP 5353) also stops `.local` name resolution and CUPS
  # auto-discovery of network printers here — add printers by IP instead.
  services.syncthing.openDefaultPorts = false;
  services.avahi.openFirewall = false;

  # Enforce the above: any module that later opens a port on this host fails
  # evaluation (and `nix flake check`) instead of silently widening it. Beyond
  # the allowed*Ports lists this also covers the other ways in: a trusted
  # interface (e.g. tailscale0) accepts *everything* on it, and raw
  # iptables/nftables rules bypass the lists entirely. extraCommands can't be
  # required empty — nixos/nat always injects its own chain cleanup there —
  # so it's checked for accept rules instead (any case, which
  # also catches the idiomatic `-j nixos-fw-accept`).
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
          && !ifaceOpen
          && fw.trustedInterfaces == [ "lo" ]
          && fw.extraInputRules == ""
          && !lib.hasInfix "accept" (lib.toLower fw.extraCommands);
        message = ''
          framework must expose no inbound ports, but the firewall is
          disabled or opens TCP ${toString fw.allowedTCPPorts} / UDP ${toString fw.allowedUDPPorts}
          (or port ranges / per-interface rules), trusts interfaces
          ${toString fw.trustedInterfaces}, or adds raw ACCEPT/input rules.
          Close it in hosts/framework/configuration.nix.
        '';
      }
    ];
}
