{ inputs, ... }:

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

  security.pam.services.login.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.hyprlock.fprintAuth = true;
}
