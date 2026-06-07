{ inputs, pkgs, ... }:

let
  # Use standard packages for maximum reliability during initial install
  ghosttyPkg = pkgs.ghostty;
  ghosttyBin = "ghostty";
in
{
  home.username = "td";
  home.homeDirectory = "/home/td";

  home.stateVersion = "25.11";

  # User specific packages
  home.packages = with pkgs; [
    # Modern CLI
    ripgrep
    bat
    eza
    fd
    bottom
    gemini-cli

    # Languages & Toolchains
    rustup
    zig
    zls
    lua
    julia
    gcc
    gnumake
    cmake
    gdb 
    
    # Python (Safe Baseline)
    (python3.withPackages (ps: with ps; [
      pip
      virtualenv
      ipython 
      requests 
      pandas 
      numpy 
    ]))

    # LSPs & Formatters
    lua-language-server
    stylua
    rust-analyzer
    pyright
    ruff 
    vscode-langservers-extracted 
    typescript-language-server
    yaml-language-server
    nil 

    # UI Survival Kit
    ghostty
    wofi
    waybar
    dunst
    libva-utils
    brave
    networkmanagerapplet
    pavucontrol 
  ];

  # Hyprland User Config
  wayland.windowManager.hyprland = {
    enable = true;
    # Use system-provided package for stability
    package = pkgs.hyprland;
    
    settings = {
      monitor = [
        "eDP-1, 2256x1504@60, 0x0, 1.25"
        ", preferred, auto, 1"
      ];

      bind = [
        "SUPER, T, exec, ${ghosttyBin}"
        "SUPER, Return, exec, ${ghosttyBin}"
        "SUPER, E, exec, thunar"
        "SUPER, Space, exec, wofi --show drun"
        "SUPER, L, exec, hyprlock"
        "SUPER_SHIFT, E, exit"
        "SUPER, X, killactive"

        # Navigation
        "SUPER, h, movefocus, l"
        "SUPER, l, movefocus, r"
        "SUPER, k, movefocus, u"
        "SUPER, j, movefocus, d"

        # Workspaces
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"

        "SUPER_SHIFT, 1, movetoworkspace, 1"
        "SUPER_SHIFT, 2, movetoworkspace, 2"
        "SUPER_SHIFT, 3, movetoworkspace, 3"
        "SUPER_SHIFT, 4, movetoworkspace, 4"
        "SUPER_SHIFT, 5, movetoworkspace, 5"
        "SUPER_SHIFT, 6, movetoworkspace, 6"
        "SUPER_SHIFT, 7, movetoworkspace, 7"
        "SUPER_SHIFT, 8, movetoworkspace, 8"
        "SUPER_SHIFT, 9, movetoworkspace, 9"
      ];

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = "yes";
          tap-to-click = "yes";
        };
      };

      gestures.workspace_swipe = "yes";

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };

      misc.force_default_wallpaper = 2;

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
        };
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      exec-once = [
        "spice-vdagent"
        "nm-applet --indicator"
        "hypridle"
        "waybar"
      ];

      windowrulev2 = [
        "opacity 0.9 0.8, class:^(ghostty)$"
        "blur, class:^(ghostty)$"
      ];
    };
  };

  # Config Links
  xdg.configFile."waybar/config".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;
  xdg.configFile."wofi/style.css".source = ./wofi/style.css;
  xdg.configFile."ghostty/config".source = ./ghostty/config;
  xdg.configFile."nvim" = { source = ./nvim; recursive = true; };

  # Services & Programs
  programs.hyprlock = {
    enable = true;
    settings = {
      background = [{ path = "screenshot"; blur_passes = 3; blur_size = 8; }];
      input-field = [{ size = "200, 50"; outline_thickness = 3; dots_center = true; outer_color = "rgb(151515)"; inner_color = "rgb(200, 200, 200)"; }];
    };
  };

  services.hypridle = {
    enable = true;
    settings = {
      general = { lock_cmd = "pidof hyprlock || hyprlock"; before_sleep_cmd = "loginctl lock-session"; };
      listener = [ { timeout = 300; on-timeout = "loginctl lock-session"; } ];
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      character.success_symbol = "[󰄛](bold pink) ";
      directory.style = "bold yellow";
    };
  };

  programs.neovim.enable = true;
  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.direnv = { enable = true; nix-direnv.enable = true; };
  programs.home-manager.enable = true;

  home.sessionVariables = {
    TERMINAL = ghosttyBin;
    BROWSER = "brave";
  };
}
