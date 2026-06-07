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
    pkgs.dunst
    pkgs.libva-utils
    pkgs.brave
    pkgs.networkmanagerapplet
    pkgs.pavucontrol 
    pkgs.brightnessctl
    pkgs.hyprpaper # Wallpaper engine
    pkgs.hyprsunset # Blue light filter

    # Fonts & Theming
    pkgs.inter
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

  # Manual Hyprland Config (Bypasses buggy HM module STUB)
  xdg.configFile."hypr/hyprland.conf".source = ./hypr/hyprland.conf;

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
