{ config, inputs, pkgs, ... }:

let
  # Extract the ghostty binary path for convenience
  ghosttyPkg = inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
  ghosttyBin = "${ghosttyPkg}/bin/ghostty";

  # Wallpaper Setup Script
  setup-wallpapers = pkgs.writeShellScriptBin "setup-wallpapers" ''
    WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
    UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    
    mkdir -p "$WALLPAPER_DIR"
    
    download_wall() {
      local url=$1
      local filename=$2
      if [ ! -f "$WALLPAPER_DIR/$filename" ]; then
        echo "Downloading $filename..."
        ${pkgs.curl}/bin/curl -L -A "$UA" "$url" -o "$WALLPAPER_DIR/$filename"
        # Validate it's actually an image
        if ! ${pkgs.file}/bin/file "$WALLPAPER_DIR/$filename" | grep -qE 'image|JPEG|PNG|WebP'; then
          echo "Error: $filename is not a valid image. Removing."
          rm "$WALLPAPER_DIR/$filename"
        fi
      fi
    }

    download_wall "https://hypr.land/imgs/blog/contestWinners/Kath.png" "hyprchan-kath.png"
 '';

  # Wallpaper Cycling Script
  cycle-wallpaper = pkgs.writeShellScriptBin "cycle-wallpaper" ''
    WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
    RANDOM_WALL=$(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \) | ${pkgs.coreutils}/bin/shuf -n 1)
    if [ -n "$RANDOM_WALL" ]; then
      ${pkgs.hyprland}/bin/hyprctl hyprpaper unload all
      ${pkgs.hyprland}/bin/hyprctl hyprpaper preload "$RANDOM_WALL"
      ${pkgs.hyprland}/bin/hyprctl hyprpaper wallpaper ",$RANDOM_WALL"
    fi
  '';
in
{
  home.username = "td";
  home.homeDirectory = "/home/td";

  home.stateVersion = "25.11";

  # User specific packages
  home.packages = [
    setup-wallpapers
    cycle-wallpaper
    # Modern CLI
    pkgs.ripgrep
    pkgs.bat
    pkgs.eza
    pkgs.fd
    pkgs.bottom
    pkgs.gh # GitHub CLI, for agentic PR/issue workflows
    
    # Languages & Toolchains
    pkgs.cargo
    pkgs.rustc
    pkgs.rustlings
    pkgs.zig
    pkgs.zls
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
    pkgs.libva-utils
    pkgs.brave
    pkgs.networkmanagerapplet
    pkgs.pavucontrol 
    pkgs.brightnessctl
    pkgs.hyprpaper # Wallpaper engine
    pkgs.hyprsunset # Blue light filter

    # AI Integration
    pkgs.gemini-cli
    pkgs.claude-code

    # Fonts & Theming
    pkgs.inter
    #pkgs.tokyonight-gtk-theme
    pkgs.catppuccin-cursors.mochaDark
    pkgs.catppuccin-papirus-folders
    pkgs.gnome-themes-extra
    pkgs.glib # for gsettings
  ];

  # GTK Theming
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.orchis-theme;
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
  gtk.gtk4.theme = config.gtk.theme;

  # Qt Theming
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
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

  # Manual Hyprland Config (Bypasses buggy HM module STUB)
  # Hyprland 0.56+ treats hyprland.conf as legacy and prefers hyprland.lua
  xdg.configFile."hypr/hyprland.lua".source = ./hypr/hyprland.lua;

  # Config Links
  xdg.configFile."waybar/config".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;
  xdg.configFile."wofi/style.css".source = ./wofi/style.css;
  xdg.configFile."ghostty/config".source = ./ghostty/config;
  xdg.configFile."nvim" = { source = ./nvim; recursive = true; };

  # hyprpaper Config
  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = "on";
      splash = false;
    };
  };

  # Services & Programs
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = false;
        ignore_empty_input = true;
      };

      auth = {
        fingerprint = {
          enabled = true;
          ready_message = "Scan fingerprint or type password";
          present_message = "Scanning...";
        };
      };

      background = [{
        path = "screenshot";
        blur_passes = 3;
        blur_size = 8;
        noise = 0.0117;
        contrast = 0.8916;
        brightness = 0.6;
        vibrancy = 0.1696;
        vibrancy_darkness = 0.0;
      }];

      input-field = [{
        size = "300, 60";
        outline_thickness = 2;
        dots_size = 0.26;
        dots_spacing = 0.3;
        dots_center = true;
        fade_on_empty = false;
        placeholder_text = "<i> Fingerprint or Password...</i>";
        outer_color = "rgb(122, 162, 247)"; # Tokyo Night Blue, matches waybar/wofi border accent
        inner_color = "rgba(26, 27, 38, 0.9)"; # Matches waybar/wofi module bg
        font_color = "rgb(192, 202, 245)"; # #c0caf5
        check_color = "rgb(158, 206, 106)"; # Green (success)
        fail_color = "rgb(247, 118, 142)"; # Red (fail)
        fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
        capslock_color = "rgb(255, 158, 100)"; # Orange
        position = "0, -60";
        halign = "center";
        valign = "center";
      }];

      label = [
        {
          # Big clock, orange like the waybar clock module
          text = "cmd[update:1000] echo \"$(date +'%I:%M %p')\"";
          color = "rgb(255, 158, 100)";
          font_size = 90;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 160";
          halign = "center";
          valign = "center";
        }
        {
          text = "cmd[update:60000] echo \"$(date +'%A, %B %d')\"";
          color = "rgb(192, 202, 245)";
          font_size = 22;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 80";
          halign = "center";
          valign = "center";
        }
        {
          text = "  $USER";
          color = "rgb(122, 162, 247)";
          font_size = 16;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 20";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };

  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 0;
        follow = "mouse";
        width = 320;
        height = "(0, 300)";
        origin = "top-right";
        offset = "(12, 40)";
        scale = 0;
        notification_limit = 5;

        progress_bar = true;
        progress_bar_height = 10;
        progress_bar_frame_width = 1;
        progress_bar_min_width = 150;
        progress_bar_max_width = 300;

        transparency = 10;
        separator_height = 2;
        separator_color = "frame";
        padding = 12;
        horizontal_padding = 12;
        text_icon_padding = 8;
        frame_width = 2;
        frame_color = "#7aa2f7"; # Blue, matches waybar border accent
        corner_radius = 12; # Matches wofi/waybar module radius

        sort = true;
        idle_threshold = 120;

        font = "JetBrainsMono Nerd Font 10";
        line_height = 2;
        markup = "full";
        format = "<b>%s</b>\\n%b";
        alignment = "left";
        vertical_alignment = "center";
        show_age_threshold = 60;
        ellipsize = "middle";
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = true;

        icon_position = "left";
        min_icon_size = 32;
        max_icon_size = 48;

        sticky_history = true;
        history_length = 20;

        mouse_left_click = "close_current";
        mouse_middle_click = "do_action, close_current";
        mouse_right_click = "close_all";
      };

      urgency_low = {
        background = "#1a1b26";
        foreground = "#c0caf5";
        frame_color = "#9ece6a"; # Green
        timeout = 5;
      };

      urgency_normal = {
        background = "#1a1b26";
        foreground = "#c0caf5";
        frame_color = "#7aa2f7"; # Blue
        timeout = 8;
      };

      urgency_critical = {
        background = "#1a1b26";
        foreground = "#c0caf5";
        frame_color = "#f7768e"; # Tokyo Night Red
        timeout = 0;
      };
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
      # Multi-line Powerline format (Complementary Palette: Blue -> Green -> Orange)
      format = ''[](#7aa2f7)$username$hostname[](bg:#9ece6a fg:#7aa2f7)$directory[](fg:#9ece6a)$git_branch$git_status
$character'';
      
      username = {
        show_always = true;
        style_user = "bg:#7aa2f7 fg:#0a0a0f bold";
        format = "[$user]($style)";
      };
      
      hostname = {
        ssh_only = false;
        style = "bg:#7aa2f7 fg:#0a0a0f bold";
        format = "[@$hostname]($style)";
      };
      
      directory = {
        style = "bg:#9ece6a fg:#0a0a0f bold";
        truncation_length = 100; # Show up to 100 levels
        truncate_to_repo = false; # DO NOT truncate to the git root
        format = "[$path]($style)";
      };
      
      git_branch = {
        symbol = " ";
        style = "bold #ff9e64"; # Tokyo Night Orange
        format = " [$symbol$branch]($style)";
      };

      git_status = {
        style = "bold #ff9e64";
        format = "([\\[$all_status$ahead_behind\\]]($style))";
      };

      character = {
        success_symbol = "[❯](bold #ff9e64) ";
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
  programs.neovim.withRuby = true;
  programs.neovim.withPython3 = true;
  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.direnv = { enable = true; nix-direnv.enable = true; };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    
    shellAliases = {
      ls = "eza --icons";
      ll = "eza -lh --icons";
      la = "eza -a --icons";
      grep = "rg";
      cat = "bat";
      cd = "z";
      rebuild = "sudo nixos-rebuild switch --flake .";
    };

    history = {
      size = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
    };
  };

  programs.bash.enable = true;
  programs.starship.enableZshIntegration = true;
  programs.zoxide.enableZshIntegration = true;
  programs.direnv.enableZshIntegration = true;
  programs.home-manager.enable = true;

  home.sessionVariables = {
    TERMINAL = ghosttyBin;
    BROWSER = "brave";
    PATH = "$HOME/.local/bin:$PATH";
  };
}
