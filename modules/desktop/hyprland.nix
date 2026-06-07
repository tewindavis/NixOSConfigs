{ inputs, pkgs, ...}:

let
  # Extract the ghostty binary path for convenience
  ghosttyPkg = inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
  ghosttyBin = "${ghosttyPkg}/bin/ghostty";
in
{
  # Enable hyprland flake
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    xwayland.enable = true;
  
    settings = {
      bind = [
        "SUPER, T, exec, ${ghosttyBin}"
        "SUPER, Return, exec, ${ghosttyBin}"
        "SUPER_SHIFT, E, exit" # exit hyprland
        "SUPER, X, killactive"
      ];

      # Basic window behavior
      input = {
        kb_layout = "us";
        follow_mouse = 1;
      };
    };


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
    TERMINAL = ghosttyBin;
    BROWSER = "brave";
  };

  # Screensharing and Portal
  xdg.portal = {
    enable = true;
  };

  # UI Survival Kit
  environment.systemPackages = [
    ghosttyPkg
    pkgs.wofi
    pkgs.waybar
    pkgs.dunst
  ];
 
}

