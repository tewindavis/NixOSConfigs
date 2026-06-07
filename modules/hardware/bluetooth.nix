{ pkgs, ... }:

{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  
  # Blueman provides a nice GUI/applet for managing connections
  services.blueman.enable = true;
}
