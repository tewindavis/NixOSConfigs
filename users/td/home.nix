{
  config,
  lib,
  pkgs,
  # Provided by home-manager's NixOS module integration: the underlying
  # system config, used below to make hyprland.lua's monitor block host-aware.
  osConfig,
  ...
}:

let
  # Absolute path to the same nixpkgs ghostty the SUPER+T/Return binds launch
  # off PATH. Not the ghostty flake input: that built unreleased git main from
  # source and dragged in its own nixpkgs, home-manager, zig overlay and
  # zon2nix, all of which ran at build time.
  ghosttyBin = "${pkgs.ghostty}/bin/ghostty";

  # hyprsunset day/night schedule, shared between hyprsunset.conf (the
  # daemon's own schedule) and waybar-hyprsunset below (so the widget's
  # "what should be active right now" math can't drift from the config
  # it's describing).
  hyprsunsetDayStart = "7:30";
  hyprsunsetNightStart = "20:00";
  hyprsunsetNightTemp = "2450"; # ~30% warmer/redder than the previous 3500K

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
      ${pkgs.awww}/bin/awww img "$RANDOM_WALL" --transition-type wipe --transition-fps 60
    fi
  '';

  # High-Contrast Blackout Toggle (SUPER+SHIFT+W): swaps to a solid black
  # background for glare/contrast relief, then restores whatever image was
  # showing before. `awww clear` defaults to black and `awww restore` recalls
  # the daemon's own last-displayed image, so no wallpaper path needs tracking
  # here — just whether we're currently in the blacked-out state.
  toggle-blackout = pkgs.writeShellScriptBin "toggle-blackout" ''
    STATE_FILE="/tmp/wallpaper-blackout-$USER"
    if [ -f "$STATE_FILE" ]; then
      ${pkgs.awww}/bin/awww restore
      rm -f "$STATE_FILE"
    else
      ${pkgs.awww}/bin/awww clear
      touch "$STATE_FILE"
    fi
  '';

  # Dropdown Scratchpad Terminal (SUPER+S): spawns a class-tagged ghostty into
  # the "scratchpad" special workspace on first call (see the scratchpad-term
  # window rule in hyprland.lua), then just toggles its visibility afterward.
  # Class must be a dotted GTK app-id ("com.td.scratchpad") — ghostty silently
  # ignores a bare-word --class value. Dispatch args are Lua expressions in
  # this Hyprland version (`hyprctl dispatch <dispatcher> <args>` no longer
  # works), confirmed live via `hyprctl dispatch 'hl.dsp.window.float()'` etc.
  toggle-scratchpad = pkgs.writeShellScriptBin "toggle-scratchpad" ''
    if ${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -e '.[] | select(.class == "com.td.scratchpad")' >/dev/null 2>&1; then
      ${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")'
    else
      ${pkgs.hyprland}/bin/hyprctl dispatch "hl.dsp.exec_cmd(\"[workspace special:scratchpad silent] ${ghosttyBin} --class=com.td.scratchpad\")"
      ${pkgs.hyprland}/bin/hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")'
    fi
  '';

  # Waybar weather module: wttr.in's IP-geolocated one-liner, as JSON for
  # waybar's custom-module return-type. Falls back to "N/A" on any fetch
  # failure (e.g. wttr.in's TLS cert is currently expired) rather than
  # erroring, so the module self-heals once the upstream issue clears.
  waybar-weather = pkgs.writeShellScriptBin "waybar-weather" ''
    WEATHER=$(${pkgs.curl}/bin/curl -fs --max-time 5 'https://wttr.in/?format=%c+%t' 2>/dev/null)
    if [ -z "$WEATHER" ]; then
      echo '{"text": " N/A", "tooltip": "Weather unavailable"}'
      exit 0
    fi
    TOOLTIP=$(${pkgs.curl}/bin/curl -fs --max-time 5 'https://wttr.in/?format=%l:+%C+%t+(feels+like+%f),+humidity+%h,+wind+%w' 2>/dev/null)
    TOOLTIP=''${TOOLTIP:-$WEATHER}
    ${pkgs.jq}/bin/jq -nc --arg text "$WEATHER" --arg tooltip "$TOOLTIP" '{text: $text, tooltip: $tooltip}'
  '';

  # Waybar power-profile module: reads/cycles power-profiles-daemon's
  # balanced/power-saver/performance profile. Only "framework" runs the
  # daemon (see modules/hardware/framework.nix); on the other two hosts
  # powerprofilesctl errors and this reports "unavailable", same graceful-
  # degradation pattern as waybar's built-in bluetooth module on utm-vm.
  waybar-power-profile = pkgs.writeShellScriptBin "waybar-power-profile" ''
    PPCTL="${pkgs.power-profiles-daemon}/bin/powerprofilesctl"

    if [ "$1" = "cycle" ]; then
      CURRENT=$($PPCTL get 2>/dev/null)
      case "$CURRENT" in
        power-saver) NEXT=balanced ;;
        balanced) NEXT=performance ;;
        performance) NEXT=power-saver ;;
        *) NEXT=balanced ;;
      esac
      $PPCTL set "$NEXT" 2>/dev/null
    fi

    PROFILE=$($PPCTL get 2>/dev/null)
    case "$PROFILE" in
      power-saver) ICON="" ;;
      balanced) ICON="" ;;
      performance) ICON="" ;;
      *)
        ICON=""
        PROFILE="unavailable"
        ;;
    esac
    ${pkgs.jq}/bin/jq -nc --arg text "$ICON" --arg tooltip "Power profile: $PROFILE (click to cycle)" '{text: $text, tooltip: $tooltip}'
  '';

  # Waybar hyprsunset widget: hyprsunset has no IPC query for its current
  # state, so this reconstructs "what should be active right now" from the
  # same schedule hyprsunset.conf uses, rather than trying to ask the
  # daemon. Manual overrides below are also sent over the daemon's own
  # control socket rather than via `hyprsunset --temperature/--identity`
  # (v0.4.0's CLI doesn't relay those to an already-running daemon — it
  # tries to bind its own CTM manager and just fails).
  #
  # Every manual override — this widget's click, or the SUPER+R/SHIFT+R
  # keybinds below, which both call into this script rather than hyprsunset
  # directly — writes {mode, epoch} to a state file, so there's one shared
  # source of truth regardless of entry point. On the next render that
  # override is honored only if it's newer than the most recent schedule
  # boundary crossing; once the real daemon's own scheduler has since
  # crossed that boundary and silently re-applied the schedule, the override
  # is stale and this falls back to the computed schedule state — so the
  # widget can't drift from what hyprsunset is actually showing on screen
  # for more than one boundary crossing.
  #
  # Usage: `waybar-hyprsunset` (render only), `waybar-hyprsunset toggle`
  # (flip day/night), `waybar-hyprsunset day` / `waybar-hyprsunset night
  # [temp]` (set explicitly — temp defaults to the scheduled night value).
  waybar-hyprsunset = pkgs.writeShellScriptBin "waybar-hyprsunset" ''
    DATE="${pkgs.coreutils}/bin/date"
    DAY_START="${hyprsunsetDayStart}"
    NIGHT_START="${hyprsunsetNightStart}"
    NIGHT_TEMP="${hyprsunsetNightTemp}"
    STATE_FILE="/tmp/hyprsunset-widget-$USER"

    now_epoch=$($DATE +%s)
    day_epoch=$($DATE -d "today $DAY_START" +%s)
    night_epoch=$($DATE -d "today $NIGHT_START" +%s)

    if [ "$now_epoch" -ge "$night_epoch" ]; then
      scheduled_mode="night"
      boundary_epoch=$night_epoch
    elif [ "$now_epoch" -ge "$day_epoch" ]; then
      scheduled_mode="day"
      boundary_epoch=$day_epoch
    else
      # Before today's day-start: still in last night's warm window, so the
      # most recent boundary crossing was yesterday's night-start.
      scheduled_mode="night"
      boundary_epoch=$($DATE -d "yesterday $NIGHT_START" +%s)
    fi

    mode="$scheduled_mode"
    overridden=false
    if [ -f "$STATE_FILE" ]; then
      read -r override_mode override_epoch < "$STATE_FILE"
      if [ -n "$override_epoch" ] && [ "$override_epoch" -gt "$boundary_epoch" ]; then
        mode="$override_mode"
        overridden=true
      else
        rm -f "$STATE_FILE"
      fi
    fi

    case "$1" in
      toggle)
        [ "$mode" = "day" ] && mode="night" || mode="day"
        ;;
      day | night)
        mode="$1"
        ;;
    esac

    case "$1" in
      toggle | day | night)
        # Re-running the hyprsunset binary here (e.g. `hyprsunset
        # --identity`) does NOT control the already-running daemon in
        # v0.4.0 — it tries to bind its own CTM manager, loses to the
        # daemon that's already bound, and fails with "A CTM manager is
        # already running" without changing anything on screen. The
        # daemon does accept plain-text commands on its own control
        # socket, so talk to that instead.
        SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.hyprsunset.sock"
        if [ "$mode" = "day" ]; then
          echo "identity" | ${pkgs.socat}/bin/socat - "UNIX-CONNECT:$SOCK"
        else
          echo "temperature ''${2:-$NIGHT_TEMP}" | ${pkgs.socat}/bin/socat - "UNIX-CONNECT:$SOCK"
        fi
        echo "$mode $now_epoch" > "$STATE_FILE"
        overridden=true
        ;;
    esac

    if [ "$mode" = "day" ]; then
      icon=""
    else
      icon=""
    fi

    if $overridden; then
      tooltip="Blue light filter: $mode (manual override, click to toggle)"
    else
      tooltip="Blue light filter: $mode (auto-scheduled, click to toggle)"
    fi

    ${pkgs.jq}/bin/jq -nc --arg text "$icon" --arg tooltip "$tooltip" --arg class "$mode" '{text: $text, tooltip: $tooltip, class: $class}'
  '';

  # Screen recording toggle (SUPER+ALT+R): mirrors the grimblast/swappy
  # screenshot pattern above, but for video. First call starts wf-recorder
  # in the background against the whole output and stashes its PID; second
  # call sends SIGINT (wf-recorder's clean-stop signal, finalizes the mp4)
  # and clears the PID file. dunstify gives a themed start/stop toast since
  # dunst is already the notification daemon here.
  toggle-recording = pkgs.writeShellScriptBin "toggle-recording" ''
    PIDFILE="/tmp/wf-recorder-$USER.pid"
    OUT_DIR="$HOME/Videos/Recordings"
    mkdir -p "$OUT_DIR"

    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
      kill -INT "$(cat "$PIDFILE")"
      rm -f "$PIDFILE"
      ${pkgs.dunst}/bin/dunstify "Screen Recording" "Stopped"
    else
      FILE="$OUT_DIR/recording-$(date +%Y%m%d-%H%M%S).mp4"
      ${pkgs.wf-recorder}/bin/wf-recorder -f "$FILE" >/tmp/wf-recorder.log 2>&1 &
      echo $! > "$PIDFILE"
      ${pkgs.dunst}/bin/dunstify "Screen Recording" "Started: $FILE"
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
    toggle-blackout
    toggle-scratchpad
    toggle-recording
    waybar-weather
    waybar-power-profile
    waybar-hyprsunset
    pkgs.power-profiles-daemon # powerprofilesctl CLI, used by waybar-power-profile above
    # Modern CLI
    pkgs.ripgrep
    pkgs.bat
    pkgs.eza
    pkgs.fd
    pkgs.bottom
    pkgs.jq # Used by toggle-scratchpad to query hyprctl clients JSON
    pkgs.gh # GitHub CLI, for agentic PR/issue workflows
    pkgs.nh # Nicer nixos-rebuild wrapper (diffed switches, easy GC); reads
    # NH_FLAKE below for the default flake path
    pkgs.fastfetch # System-info splash, shown on interactive shell start (see initContent)

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

    # Neovim LSP servers, formatters & linters. Installed here (Nix-managed)
    # rather than via Mason, so editor tooling stays reproducible with
    # nixos-rebuild instead of drifting from whatever Mason downloaded at
    # runtime; Mason itself is disabled in nvim/lua/plugins/mason.lua. Names
    # below are grouped by the LazyVim language extra that consumes them
    # (see nvim/lua/config/lazy.lua).
    pkgs.rust-analyzer # lang.rust (rustaceanvim)
    pkgs.rustfmt # rust-analyzer shells out to this for formatting
    pkgs.nil # lang.nix (nil_ls)
    pkgs.nixfmt # lang.nix formatter; same binary this repo's `nix fmt` uses
    pkgs.statix # lang.nix linter
    pkgs.deadnix # dead-code checks, same as this repo's treefmt.nix
    pkgs.basedpyright # lang.python LSP (see vim.g.lazyvim_python_lsp)
    pkgs.ruff # lang.python lint + format
    pkgs.clang-tools # lang.clangd: clangd, clang-format, clang-tidy
    pkgs.lua-language-server # Lua LSP (LazyVim core, for editing this config)
    pkgs.stylua # Lua formatter (LazyVim core default)
    pkgs.vscode-langservers-extracted # lang.json (jsonls)
    pkgs.yaml-language-server # lang.yaml (yamlls)
    pkgs.taplo # lang.toml (LSP + formatter)
    pkgs.marksman # lang.markdown
    pkgs.markdownlint-cli2 # lang.markdown linter
    pkgs.tree-sitter # CLI nvim-treesitter needs to compile parsers; without
    # this and with Mason disabled, `:TSInstall`/ensure_installed silently
    # can't fetch any parser at all

    # Python (Base)
    (pkgs.python3.withPackages (
      ps: with ps; [
        pip
        virtualenv
        ipython
        requests
        pandas
        numpy
      ]
    ))

    # UI Survival Kit
    pkgs.ghostty
    pkgs.wofi
    pkgs.waybar
    pkgs.libva-utils
    pkgs.brave
    pkgs.networkmanagerapplet
    pkgs.pavucontrol
    pkgs.brightnessctl
    pkgs.awww # Wallpaper engine w/ animated transitions (formerly swww,
    # renamed upstream; same CLI/daemon shape)
    pkgs.hypridle # Idle daemon (autolock/DPMS); unlike hyprlock/hyprpaper,
    # the HM module for this doesn't add its package to home.packages
    pkgs.hyprsunset # Blue light filter
    pkgs.grimblast # Screenshot tool (SUPER+SHIFT+S)
    pkgs.swappy # Screenshot annotation, chained after grimblast (see keybind)
    pkgs.hyprpicker # On-screen color picker (SUPER+C)
    pkgs.wl-clipboard # wl-copy/wl-paste, needed by cliphist
    pkgs.cliphist # Clipboard history (SUPER+V)
    pkgs.wl-clip-persist # Keeps the live clipboard selection alive after its
    # source app/window closes, which wlroots otherwise drops (autostarted below)
    pkgs.swayosd # Volume/brightness on-screen display
    pkgs.imv # Image viewer, for screenshots/images opened from Thunar
    pkgs.zathura # PDF viewer, for docs opened from Thunar
    pkgs.mpv # Video/audio player, for media opened from Thunar
    pkgs.wf-recorder # Screen recording backend for toggle-recording (SUPER+ALT+R)
    pkgs.keepassxc # Password manager
    pkgs.resources # GTK4/libadwaita system monitor (GUI complement to bottom/htop)
    pkgs.rclone # CLI sync/mount for cloud storage remotes
    pkgs.gnome-firmware # GUI firmware updater, complements fwupd (see framework host)
    pkgs.syncthingtray # Waybar tray icon/control for the syncthing service
    # (modules/services/syncthing.nix)

    # AI Integration
    pkgs.antigravity-cli
    pkgs.claude-code

    # Fonts & Theming
    pkgs.inter
    pkgs.adw-gtk3
    pkgs.catppuccin-cursors.mochaBlue
    pkgs.catppuccin-papirus-folders
    pkgs.gnome-themes-extra
  ];

  # GTK Theming
  # adw-gtk3 mirrors libadwaita's flat GTK4 look for GTK3 apps; native GTK4/
  # libadwaita apps need no theme override, just color-scheme + accent-color
  # below, so they stay in sync automatically.
  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    font = {
      name = "Inter";
      size = 10;
    };
    iconTheme = {
      name = "Papirus-Dark";
    };
    cursorTheme = {
      # Blue accent, not the neutral "Dark" variant, so the cursor matches
      # the blue accent used by waybar/wofi/hyprlock/GTK accent-color.
      name = "catppuccin-mocha-blue-cursors";
      package = pkgs.catppuccin-cursors.mochaBlue;
      # Explicit size so it renders consistently at the framework host's
      # 1.175 HiDPI scale instead of falling back to an unscaled default.
      size = 24;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    # GTK4/libadwaita apps theme natively off color-scheme + accent-color
    # (set via dconf below) rather than the GTK3 adw-gtk3-dark theme.
    gtk4.theme = null;
  };

  # Qt Theming
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "adwaita-dark";
  };

  # XDG Desktop Portal Color Scheme
  # Declarative source of truth for GTK/libadwaita theming — no need to
  # re-run gsettings at every Hyprland startup (see hyprland.nix autostart).
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus-Dark";
      accent-color = "blue";
      cursor-size = 24;
      font-name = "Inter 10";
      document-font-name = "Inter 10";
    };
  };

  # Manual Hyprland Config (Bypasses buggy HM module STUB)
  # Hyprland 0.56+ treats hyprland.conf as legacy and prefers hyprland.lua.
  # This same file is shared across all three hosts (see flake.nix's mkHost),
  # so @HOSTNAME@ is substituted here rather than hardcoding one host's
  # monitor mode/scale into a config that also deploys to dl-prototype/utm-nixos.
  xdg.configFile."hypr/hyprland.lua".text =
    builtins.replaceStrings
      [ "@HOSTNAME@" ]
      [
        osConfig.networking.hostName
      ]
      (builtins.readFile ./hypr/hyprland.lua);

  # hyprsunset auto day/night schedule: hyprsunset is a Hyprlang tool (not
  # Lua like hyprland.lua), and reads this from its default XDG path on
  # startup. Run bare (see autostart in hyprland.lua) it becomes a daemon
  # that watches the clock and switches profiles itself — f.lux/redshift
  # style — while the SUPER+R/SUPER+SHIFT+R keybinds still work as IPC
  # clients against that daemon for a manual override until the next
  # scheduled switch. Times reuse the same values the old fixed autostart
  # (3500K) and the SHIFT+R "day mode" reset (identity) already used.
  xdg.configFile."hypr/hyprsunset.conf".text = ''
    profile {
        time = ${hyprsunsetDayStart}
        identity = true
    }

    profile {
        time = ${hyprsunsetNightStart}
        temperature = ${hyprsunsetNightTemp}
    }
  '';

  # Config Links
  xdg.configFile."waybar/config".source = ./waybar/config.jsonc;
  xdg.configFile."waybar/style.css".source = ./waybar/style.css;
  xdg.configFile."wofi/style.css".source = ./wofi/style.css;
  # No HM module here would actually help: hyprland.nix/hyprland.lua don't
  # activate graphical-session.target (that's a UWSM thing, and this config
  # doesn't use UWSM), so a systemd-user-gated services.swayosd would never
  # start — swayosd-server has to be launched directly from autostart below,
  # picking up this default-location style.css on its own.
  xdg.configFile."swayosd/style.css".source = ./swayosd/style.css;
  # wlogout has no HM option for its icon set, so it's linked manually
  # alongside programs.wlogout below (which handles layout + style; wlogout
  # itself is launched on demand by the keybind, not autostarted, so it has
  # no graphical-session.target dependency to worry about).
  # Recolored from the stock set (originally flat lavender) to match the
  # Tokyo Night accents used everywhere else: blue for lock/logout, green for
  # suspend/hibernate, orange for reboot, red for shutdown.
  xdg.configFile."wlogout/icons" = {
    source = ./wlogout/icons;
    recursive = true;
  };
  xdg.configFile."ghostty/config".source = ./ghostty/config;
  # save_dir matches XDG_SCREENSHOTS_DIR below; show_panel keeps the
  # annotate toolbar open, early_exit closes swappy once you copy/save.
  xdg.configFile."swappy/config".text = ''
    [Default]
    save_dir=${config.home.homeDirectory}/Pictures/Screenshots
    save_filename_format=swappy-%Y%m%d-%H%M%S.png
    show_panel=true
    early_exit=true
  '';
  xdg.configFile."nvim" = {
    source = ./nvim;
    recursive = true;
  };

  # awww Config (wallpaper daemon; see cycle-wallpaper above for transitions)
  services.awww.enable = true;

  # Kanshi: auto-switches monitor layout when the Framework docks/undocks.
  # This block only generates ~/.config/kanshi/config: the HM service it also
  # creates is gated on graphical-session.target, which this non-UWSM session
  # never reaches, so kanshi itself is launched from hyprland.lua's autostart
  # (like swayosd-server). "laptop" (just the internal panel) always matches;
  # "docked" is a
  # template — kanshi simply won't match it until CHANGE_ME below is replaced
  # with the real external display's name from `hyprctl monitors` once one is
  # actually plugged in (can't be known ahead of time from here).
  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "laptop";
        profile.outputs = [ { criteria = "eDP-1"; } ];
      }
      {
        profile.name = "docked";
        profile.outputs = [
          { criteria = "eDP-1"; }
          {
            criteria = "CHANGE_ME"; # e.g. "Dell Inc. DELL U2718Q ABC123"
            mode = "preferred";
          }
        ];
      }
    ];
  };

  # Power menu (SUPER+SHIFT+P)
  programs.wlogout = {
    enable = true;
    style = ./wlogout/style.css;
    layout = [
      {
        label = "lock";
        action = "hyprlock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        # Lua-expression dispatch: the classic `hyprctl dispatch exit` form
        # errors on Hyprland 0.56+ (see docs/gotchas.md).
        action = "hyprctl dispatch 'hl.dsp.exit()'";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
    ];
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

      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.6;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        }
      ];

      input-field = [
        {
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
        }
      ];

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
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
      };
      listener = [
        {
          # Lock at 5 min idle (loginctl broadcasts the Lock signal that
          # general.lock_cmd above responds to).
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          # DPMS off 5s after locking; on-resume wakes it on any input.
          # `hyprctl dispatch dpms off/on` errors on this Hyprland version
          # (dispatch args are Lua expressions now); confirmed the fix live
          # via `hyprctl monitors -j | jq '.[0].dpmsStatus'` toggling correctly.
          timeout = 305;
          on-timeout = "hyprctl dispatch 'hl.dsp.dpms(false)'";
          on-resume = "hyprctl dispatch 'hl.dsp.dpms(true)'";
        }
        {
          # Auto-suspend after 20 min idle, well past the lock/DPMS stage
          # above, to save battery when left unattended.
          timeout = 1200;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = true;
      # Multi-line Powerline format (Complementary Palette: Blue -> Green -> Orange)
      format = ''
        [](#7aa2f7)$username$hostname[](bg:#9ece6a fg:#7aa2f7)$directory[](fg:#9ece6a)$git_branch$git_status
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
      nix_shell = {
        disabled = true;
      };
      package = {
        disabled = true;
      };
      python = {
        disabled = true;
      };
      rust = {
        disabled = true;
      };
    };
  };

  # So Thunar/xdg-open have somewhere to send images/PDFs instead of erroring
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf" = "org.pwmt.zathura.desktop";
      "image/png" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "video/mp4" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "audio/mpeg" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";
      "application/x-keepass2" = "org.keepassxc.KeePassXC.desktop";
      "application/zip" = "xarchiver.desktop";
      "application/x-7z-compressed" = "xarchiver.desktop";
      "application/vnd.rar" = "xarchiver.desktop";
      "application/x-tar" = "xarchiver.desktop";
      "application/gzip" = "xarchiver.desktop";
    };
  };

  programs.neovim.enable = true;
  programs.neovim.withRuby = true;
  programs.neovim.withPython3 = true;
  # withRuby/withPython3 make HM generate an init.lua that sets
  # vim.g.{python3,ruby}_host_prog to the Nix-built provider binaries, and by
  # default it writes that to xdg.configFile."nvim/init.lua" — which collides
  # with our own recursively-linked ./nvim (below) and gets silently dropped
  # (visible as a "conflicts with recursively symlinked file" build warning),
  # leaving those two options inert. sideloadInitLua instead loads the
  # generated content via a wrapper --cmd flag, so it coexists with our
  # hand-managed init.lua rather than fighting it for the same path.
  programs.neovim.sideloadInitLua = true;
  programs.fzf.enable = true;
  programs.zoxide.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
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

    # Themed system-info splash on shell start; TERM=dumb guard matches the
    # starship one above (VS Code's shell integration, CI, etc).
    initContent = lib.mkAfter ''
      if [[ $TERM != "dumb" ]]; then
        fastfetch
      fi
    '';
  };

  programs.bash.enable = true;
  programs.starship.enableZshIntegration = true;
  programs.zoxide.enableZshIntegration = true;
  programs.direnv.enableZshIntegration = true;
  programs.home-manager.enable = true;

  # grimblast (SUPER+SHIFT+S) reads this to decide where to save screenshots
  home.sessionVariables = {
    TERMINAL = ghosttyBin;
    BROWSER = "brave";
    XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";
    PATH = "$HOME/.local/bin:$PATH";
    NH_FLAKE = "/etc/nixos"; # lets `nh os switch`/`nh os boot` find this flake from anywhere
  };

  home.activation.createScreenshotsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.home.homeDirectory}/Pictures/Screenshots
  '';
}
