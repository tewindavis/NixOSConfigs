{ inputs, pkgs, ...}:

let
  # Extract the ghostty binary path for convenience
  ghostty = inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  # Enable hyprland flake
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    xwayland.enable = true;
  };
  
  # Wayland hardware-specific environment variables
  environment.sessionVariables = {
    # If using NVIDIA, these are crucial
    #   but they help rendering on other systems as well
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    
    # Hint for electron apps
    NIXOS_OZONE_WL = "1";

    # Default programs
    TERMINAL = "ghostty";
  };

  # Screensharing and Portal
  xdg.portal = {
    enable = true;
  };

  # UI Survival Kit
  environment.systemPackages = [
    # Pull Ghostty directly from flake
    inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default

    pkgs.wofi
    pkgs.waybar
    pkgs.dunst
  ];
  
  # Bind ghostty in hyprland
  wayland.windowManager.hyprland.settings = {
    bind = [
      "SUPER, T, exec, ${ghostty}/bin/ghostty"
      "SUPER, Return, exec, ${ghostty}/bin/ghostty"
    ];
  };

}

