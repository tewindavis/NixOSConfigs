{ inputs, pkgs, ... }:

let
  # Extract the ghostty binary path for convenience
  ghosttyPkg = inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
  ghosttyBin = "${ghosttyPkg}/bin/ghostty";
in
{
  home.username = "td";
  home.homeDirectory = "/home/td";

  home.stateVersion = "25.11";

  # User specific packages
  home.packages = [
    # Modern CLI
    pkgs.ripgrep
    pkgs.bat
    pkgs.eza
    pkgs.fd
    pkgs.bottom
    
    # Languages & Toolchains
    pkgs.rustup
    pkgs.rustlings
    pkgs.julia
    pkgs.octave
    pkgs.lua
    pkgs.gcc
    pkgs.gnumake
    pkgs.cmake
    
    # Python (Base)
    (pkgs.python3.withPackages (ps: with ps; [
      pip
      virtualenv
      ipython 
      requests 
      pandas 
      numpy 
    ]))

    # UI Survival Kit
    pkgs.ghostty
    pkgs.wofi
    pkgs.waybar
    pkgs.dunst
    pkgs.libva-utils
    pkgs.brave
    pkgs.networkmanagerapplet
    pkgs.pavucontrol 
    pkgs.brightnessctl

    # Fonts
    pkgs.inter

    # Theming support
    pkgs.tokyonight-gtk-theme
    pkgs.catppuccin-cursors.mochaDark
    pkgs.catppuccin-papirus-folders
    pkgs.gnome-themes-extra
    pkgs.glib # for gsettings
  ];

  # GTK Theming
  gtk = {
    enable = true;
    theme = {
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };
    font = {
      name = "Inter";
      size = 10;
    };
    iconTheme = {
      name = "Papirus-Dark";
    };
    cursorTheme = {
      name = "catppuccin-mocha-dark-cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
  };

  # Qt Theming
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };

  # XDG Desktop Portal Color Scheme
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      font-name = "Inter 10";
      document-font-name = "Inter 10";
    };
  };

  # Hyprland User Config
  wayland.windowManager.hyprland = {
    enable = true;
    # Use system-provided package for stability
    package = pkgs.hyprland;
    
    settings = {
      monitor = ",2256x1504@60,auto,1.17";

      xwayland = {
        force_zero_scaling = true;
      };

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

      # Media Keys
      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      bindl = [
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ];

        # Input Configuration

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
        };
      };

      gesture = [
        "3, horizontal, workspace"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(ff007cee) rgba(fff000ee) 45deg"; # Neon Pink & Yellow
        "col.inactive_border" = "rgba(1a1a20aa)";
        layout = "dwindle";
      };

      misc = {
        force_default_wallpaper = 2;
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 6;
          passes = 3; # Increased for bolder look
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
        "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'"
        "gsettings set org.gnome.desktop.interface gtk-theme 'Tokyonight-Dark'"
      ];

      windowrule = [
        "opacity 0.9 0.8, match:class ^(ghostty)$"
        "no_blur 0, match:class ^(ghostty)$"
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
    enableBashIntegration = true;
    settings = {
      add_newline = true;
      # Multi-line Powerline format (Zero Spaces between segments to prevent gaps)
      format = ''[](#ff007c)$username$hostname[](bg:#fff000 fg:#ff007c)$directory[](fg:#fff000)$git_branch$git_status
$character'';
      
      username = {
        show_always = true;
        style_user = "bg:#ff007c fg:#0a0a0f bold";
        format = "[$user]($style)";
      };
      
      hostname = {
        ssh_only = false;
        style = "bg:#ff007c fg:#0a0a0f bold";
        format = "[@$hostname]($style)";
      };
      
      directory = {
        style = "bg:#fff000 fg:#0a0a0f bold";
        truncation_length = 3;
        format = "[$path]($style)"; # Removed leading space
      };
      
      git_branch = {
        symbol = " ";
        style = "bold #ff007c";
        format = " [$symbol$branch]($style)";
      };

      git_status = {
        style = "bold #fff000";
        format = "([\\[$all_status$ahead_behind\\]]($style))";
      };

      character = {
        success_symbol = "[❯](bold #ff007c) ";
        error_symbol = "[❯](bold red) ";
      };

      # Disable noisy modules
      nix_shell = { disabled = true; };
      package = { disabled = true; };
      python = { disabled = true; };
      rust = { disabled = true; };
    };
  };

  programs.neovim.enable = true;
  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.direnv = { enable = true; nix-direnv.enable = true; };
  programs.bash.enable = true;
  programs.home-manager.enable = true;

  home.sessionVariables = {
    TERMINAL = ghosttyBin;
    BROWSER = "brave";
  };
}
