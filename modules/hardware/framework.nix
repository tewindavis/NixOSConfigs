{
  inputs,
  pkgs,
  ...
}:
let
  # Lithium cells age fastest sitting at a full charge, and this laptop spends
  # most of its life on the dock. The EC enforces the cap itself, so it holds
  # even while the machine is off. `battery-limit full` (home.nix) raises it
  # to 100 for travel; the unit below puts it back at the next boot, which is
  # the intended escape hatch rather than a setting to remember to undo.
  # The CalDigit TS4's upstream Intel hub (USB 8087:0b40) stops answering USB
  # descriptor requests once the dock has been attached for a while. fwupd
  # blocks on it during device enumeration: `fwupdtool` gives up after 42s
  # and carries on, but the daemon never gets past it — fwupd.service failed
  # its 3-minute start timeout, and still failed when given 15 minutes, so
  # this is a wedged device rather than a slow one. `no-probe` tells fwupd
  # not to touch it; everything else, including the firmware updates this
  # laptop actually needs, enumerates normally again.
  #
  # It goes in /var/lib rather than /etc because those are the only two
  # places fwupd 2.1.6 loads quirks from (the other is its own store path):
  #   FuQuirks loading quirks from <store>/share/fwupd/quirks.d
  #   FuQuirks loading quirks from /var/lib/fwupd/quirks.d
  # so tmpfiles links the file in from the store, keeping it declarative.
  dockHubQuirk = pkgs.writeText "99-caldigit-ts4-hub.quirk" ''
    [USB\VID_8087&PID_0B40]
    Flags = no-probe
  '';

  chargeLimit = 80;
  thresholdFile = "/sys/class/power_supply/BAT1/charge_control_end_threshold";
  applyLimit = pkgs.writeShellScript "apply-charge-limit" ''
    # Absent on a host without the framework EC module, or before it loads.
    [ -w ${thresholdFile} ] || exit 0
    echo ${toString chargeLimit} > ${thresholdFile}
  '';
in
{
  imports = [
    # Confirmed generation: Framework Laptop 13 (AMD Ryzen 7040Series), Ryzen 7
    # 7840U. Brings AMD pstate/GPU/microcode setup, the amdgpu PSR-hang
    # workaround kernel param, the framework-laptop-kmod EC module (battery
    # charge limit/LEDs via sysfs) and framework-tool. TLP stays off because
    # power-profiles-daemon is enabled below.
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
  ];

  # Additional framework-specific tweaks can go here
  services.fwupd.enable = true; # Recommended for Framework bios updates
  services.fprintd.enable = true; # Fingerprint reader

  # The USB4/Thunderbolt controller runs at security level "user", so the
  # kernel leaves docks (e.g. CalDigit TS4) unauthorized until userspace
  # approves them. bolt does that; enroll a device once with
  # `boltctl enroll --policy auto <uuid>` and it's authorized on every plug.
  services.hardware.bolt.enable = true;

  # Battery/thermal profile switching (balanced/power-saver/performance) via
  # powerprofilesctl; waybar's custom/power-profile module (see waybar
  # config.jsonc) reads/cycles it. Mutually exclusive with TLP by design.
  services.power-profiles-daemon.enable = true;

  # Re-applied on resume as well as at boot: the EC keeps the threshold over a
  # suspend, but not over the firmware reset that a battery disconnect or an
  # EC update causes, and re-running it is free.
  systemd.services.battery-charge-limit = {
    description = "Cap battery charge at ${toString chargeLimit}%";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = applyLimit;
    };
  };
  powerManagement.resumeCommands = "${applyLimit}";

  systemd.tmpfiles.settings."10-fwupd-dock-quirk" = {
    "/var/lib/fwupd/quirks.d".d = {
      user = "root";
      group = "root";
      mode = "0755";
    };
    "/var/lib/fwupd/quirks.d/99-caldigit-ts4-hub.quirk"."L+".argument = "${dockHubQuirk}";
  };

  security.pam.services.login.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.hyprlock.fprintAuth = true;
}
