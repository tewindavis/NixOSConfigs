{ inputs, ... }:

{
  imports = [
    # inputs.nixos-hardware.nixosModules.framework-13-7040-amd 
    # ^ Commented out to ensure build success on unknown Framework generation.
    # Re-enable this once the basic build succeeds.
  ];

  # Additional framework-specific tweaks can go here
  services.fwupd.enable = true; # Recommended for Framework bios updates
  services.fprintd.enable = true; # Fingerprint reader

  security.pam.services.login.fprintAuth = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.hyprlock.fprintAuth = true;
}
