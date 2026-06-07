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
  home.packages = with pkgs; [
    # Modern CLI
    ripgrep
    bat
    eza
    fd
    bottom

    # Languages & Toolchains
    # Rust
    rustup
    rustlings
    
    # Zig
    zig
    zls # Zig Language Server
    
    # Lua
    lua
    
    # Julia
    julia
    
    # C/C++
    gcc
    gnumake
    cmake
    gdb # Already in rl-binary for one host, but good for all
    
    # Python
    (python3.withPackages (ps: with ps; [
      pip
      virtualenv
      black # formatter
      isort # import sorter
    ]))

    # LSPs, Formatters, Linters for LazyVim
    lua-language-server
    stylua
    rust-analyzer
    pyright
    ruff # Fast python linter/formatter
    nodePackages.vscode-langservers-extracted # HTML/CSS/JSON/ESLint
    nodePackages.typescript-language-server
    yaml-language-server
    nil # Nix LSP

    # UI Survival Kit
    ghosttyPkg
    wofi
    waybar
    dunst
    libva-utils
    brave
    networkmanagerapplet
  ];

  # Hyprland User Config
  wayland.windowManager.hyprland = {
    enable = true;
    # Use the same package as the system for consistency
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    
    settings = {
      # Monitors
      monitor = [
        "eDP-1, 2256x1504@60, 0x0, 1.25" # Framework 13
        ", preferred, auto, 1"           # Others
      ];

      # Keybindings
      bind = [
        "SUPER, T, exec, ${ghosttyBin}"
        "SUPER, Return, exec, ${ghosttyBin}"
        "SUPER, E, exec, thunar"
        "SUPER, Space, exec, wofi --show drun"
        "SUPER, L, exec, hyprlock"
        "SUPER_SHIFT, E, exit"
        "SUPER, X, killactive"

        # Focus Navigation
        "SUPER, h, movefocus, l"
        "SUPER, l, movefocus, r"
        "SUPER, k, movefocus, u"
        "SUPER, j, movefocus, d"

        # Workspace Switching
        "SUPER, 1, workspace, 1"
        "SUPER, 2, workspace, 2"
        "SUPER, 3, workspace, 3"
        "SUPER, 4, workspace, 4"
        "SUPER, 5, workspace, 5"
        "SUPER, 6, workspace, 6"
        "SUPER, 7, workspace, 7"
        "SUPER, 8, workspace, 8"
        "SUPER, 9, workspace, 9"

        # Move to Workspace
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

      # Input Configuration
      input = {
        kb_layout = "us";
        follow_mouse = 1; # Mouse switches focus
        
        touchpad = {
          natural_scroll = "yes";
          tap-to-click = "yes";
        };
      };

      # Gestures
      gestures = {
        workspace_swipe = "yes"; # Swipe to move spaces
      };

      # Aesthetics
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };

      # Mascot / Misc
      misc = {
        force_default_wallpaper = 2; # 2 forces the mascot (Hypr-chan) to always show
        disable_hyprland_logo = false;
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
        };
        # Shadow removed in newer Hyprland versions or renamed, 
        # using safe modern defaults.
      };

      # Hardware-specific but safe defaults
      exec-once = [
        "spice-vdagent" # Safe to keep here, only does something if spice is present
        "nm-applet --indicator" # WiFi tray icon
        "hypridle"
      ];
    };
  };

  # Lock Screen Config
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading = true;
        hide_cursor = true;
      };

      background = [
        {
          path = "screenshot"; # Use a screenshot of current desktop
          color = "rgba(25, 20, 20, 1.0)";
          blur_passes = 3; # Heavy blur
          blur_size = 8;
        }
      ];

      input-field = [
        {
          size = "200, 50";
          outline_thickness = 3;
          dots_size = 0.33;
          dots_spacing = 0.15;
          dots_center = true;
          outer_color = "rgb(151515)";
          inner_color = "rgb(200, 200, 200)";
          font_color = "rgb(10, 10, 10)";
          fade_on_empty = true;
          placeholder_text = "<i>Input Password...</i>";
          hide_input = false;
          position = "0, -20";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  # Idle Daemon Config
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # avoid starting multiple hyprlock instances
        before_sleep_cmd = "loginctl lock-session"; # lock before suspend
        after_sleep_cmd = "hyprctl dispatch dpms on"; # to avoid stuck black screen
      };

      listener = [
        {
          timeout = 300; # 5 minutes
          on-timeout = "loginctl lock-session"; # lock screen when timeout has passed
        }
        {
          timeout = 330; # 5.5 minutes
          on-timeout = "hyprctl dispatch dpms off"; # screen off after 5.5 minutes
          on-resume = "hyprctl dispatch dpms on"; # screen on when activity is detected
        }
      ];
    };
  };

  # User session variables
  home.sessionVariables = {
    TERMINAL = ghosttyBin;
    BROWSER = "brave";
  };

  # Neovim
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    
    # Extra packages for nvim functionality
    extraPackages = with pkgs; [
      git
      gcc
      gnumake
      unzip
      wget
      curl
      tree-sitter
    ];
  };

  # Link Neovim Config
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };

  # Modern CLI tools with built-in HM modules
  programs.fzf.enable = true;
  programs.zoxide.enable = true;

  # Default Browser / Mime Apps
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "brave-browser.desktop" ];
      "text/xml" = [ "brave-browser.desktop" ];
      "x-scheme-handler/http" = [ "brave-browser.desktop" ];
      "x-scheme-handler/https" = [ "brave-browser.desktop" ];
      "x-scheme-handler/about" = [ "brave-browser.desktop" ];
      "x-scheme-handler/unknown" = [ "brave-browser.desktop" ];
    };
  };
  
  # Direnv for automatic nix-shell/flake loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
