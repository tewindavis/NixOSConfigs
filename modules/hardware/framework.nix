{ inputs, ... }:

{
  imports = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd # Assuming AMD, adjust if Intel
  ];

  # Additional framework-specific tweaks can go here
}
