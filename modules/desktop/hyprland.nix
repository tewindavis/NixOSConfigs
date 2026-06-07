{ pkgs, ...}:

{
  # Enable Hyprland at system level for SUID wrappers and system-wide integration
  programs.hyprland = {
    enable = true;
  };

  # Wayland hardware-specific environment variables (System Level)
  environment.sessionVariables = {
    # If using NVIDIA, these are crucial
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    
    # Hint for electron apps
    NIXOS_OZONE_WL = "1";
  };

  # Screensharing and Portal
  xdg.portal = {
    enable = true;
  };
}
