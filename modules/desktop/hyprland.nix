{ pkgs, ...}:

{
  # Enable Hyprland at system level for SUID wrappers and system-wide integration
  programs.hyprland = {
    enable = true;
  };

  # Log in straight to Hyprland via a TUI greeter
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --cmd start-hyprland";
      };
    };
  };

  # Wayland hardware-specific environment variables (System Level)
  environment.sessionVariables = {
    # If using NVIDIA, these are crucial
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    
    # Hint for electron apps
    NIXOS_OZONE_WL = "1";

    # Force dark mode for apps that check these vars
    GTK_THEME = "Adwaita-dark";
  };

  # Screensharing and Portal
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };
}
