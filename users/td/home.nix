{
  config,
  lib,
  pkgs,
  # Provided by home-manager's NixOS module integration: the underlying
  # system config, used below to make hyprland.lua's monitor block host-aware.
  osConfig,
  # This host's attribute in flake.nix (not always its hostname).
  flakeAttr,
  ...
}:

let
  # Absolute path to the same nixpkgs ghostty the SUPER+T/Return binds launch
  # off PATH. Not the ghostty flake input: that built unreleased git main from
  # source and dragged in its own nixpkgs, home-manager, zig overlay and
  # zon2nix, all of which ran at build time.
  ghosttyBin = "${pkgs.ghostty}/bin/ghostty";

  # Tokyo Night for GTK3 (adw-gtk3) and GTK4/libadwaita apps: Thunar,
  # pavucontrol, blueman, nm-connection-editor, Resources, ... Both read
  # these named colors from gtk.css. Laid out like tokyonight itself: darker
  # header bars and sidebars around #1a1b26 content, all palette values.
  gtkNamedColors = ''
    @define-color window_bg_color #1a1b26;
    @define-color window_fg_color #c0caf5;
    @define-color view_bg_color #1a1b26;
    @define-color view_fg_color #c0caf5;
    @define-color headerbar_bg_color #15161e;
    @define-color headerbar_fg_color #c0caf5;
    @define-color headerbar_backdrop_color #15161e;
    @define-color sidebar_bg_color #15161e;
    @define-color sidebar_fg_color #c0caf5;
    @define-color sidebar_backdrop_color #15161e;
    @define-color popover_bg_color #1a1b26;
    @define-color popover_fg_color #c0caf5;
    @define-color dialog_bg_color #1a1b26;
    @define-color dialog_fg_color #c0caf5;
    @define-color card_fg_color #c0caf5;
    @define-color accent_color #7aa2f7;
    @define-color accent_bg_color #7aa2f7;
    @define-color accent_fg_color #15161e;
    @define-color destructive_color #f7768e;
    @define-color destructive_bg_color #f7768e;
    @define-color destructive_fg_color #15161e;
    @define-color success_color #9ece6a;
    @define-color warning_color #e0af68;
    @define-color error_color #f7768e;
  '';
  # Newer libadwaita reads CSS variables instead of @define-color; setting
  # both covers either version.
  gtkCssVariables = ''
    :root {
      --window-bg-color: #1a1b26;
      --window-fg-color: #c0caf5;
      --view-bg-color: #1a1b26;
      --view-fg-color: #c0caf5;
      --headerbar-bg-color: #15161e;
      --headerbar-fg-color: #c0caf5;
      --headerbar-backdrop-color: #15161e;
      --sidebar-bg-color: #15161e;
      --sidebar-fg-color: #c0caf5;
      --sidebar-backdrop-color: #15161e;
      --popover-bg-color: #1a1b26;
      --popover-fg-color: #c0caf5;
      --dialog-bg-color: #1a1b26;
      --dialog-fg-color: #c0caf5;
      --card-fg-color: #c0caf5;
      --accent-color: #7aa2f7;
      --accent-bg-color: #7aa2f7;
      --accent-fg-color: #15161e;
      --destructive-color: #f7768e;
      --destructive-bg-color: #f7768e;
      --destructive-fg-color: #15161e;
      --success-color: #9ece6a;
      --warning-color: #e0af68;
      --error-color: #f7768e;
    }
  '';

  # qt5ct/qt6ct color scheme: 21 colors per state in QPalette role order
  # (WindowText, Button, Light, Midlight, Dark, Mid, Text, BrightText,
  # ButtonText, Base, Window, Shadow, Highlight, HighlightedText, Link,
  # LinkVisited, AlternateBase, NoRole, ToolTipBase, ToolTipText,
  # PlaceholderText), the format of qt6ct's bundled schemes.
  qtColorScheme =
    let
      active = [
        "#ffc0caf5" # WindowText
        "#ff3b3d4d" # Button
        "#ff414868" # Light
        "#ff3b3d4d" # Midlight
        "#ff0a0b10" # Dark
        "#ff15161e" # Mid
        "#ffc0caf5" # Text
        "#ffffffff" # BrightText
        "#ffc0caf5" # ButtonText
        "#ff15161e" # Base
        "#ff1a1b26" # Window
        "#ff000000" # Shadow
        "#ff7aa2f7" # Highlight
        "#ff15161e" # HighlightedText
        "#ff7aa2f7" # Link
        "#ffbb9af7" # LinkVisited
        "#ff1a1b26" # AlternateBase
        "#ff1a1b26" # NoRole
        "#ff1a1b26" # ToolTipBase
        "#ffc0caf5" # ToolTipText
        "#80c0caf5" # PlaceholderText
      ];
      # Disabled text/labels drop to the palette's muted slate.
      disabled = lib.imap0 (
        i: c:
        if
          builtins.elem i [
            0
            6
            8
          ]
        then
          "#ff414868"
        else
          c
      ) active;
      join = lib.concatStringsSep ", ";
    in
    pkgs.writeText "tokyonight-night.conf" ''
      [ColorScheme]
      active_colors=${join active}
      disabled_colors=${join disabled}
      inactive_colors=${join active}
    '';
  qtctSettings = {
    Appearance = {
      custom_palette = true;
      color_scheme_path = "${qtColorScheme}";
      style = "Fusion";
      icon_theme = "Papirus-Dark";
      standard_dialogs = "default";
    };
  };

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

  # Wallpaper Cycling Script: each monitor gets its own random image (all
  # different while there are enough), growing out from the cursor on the
  # monitor it's on and from the center elsewhere. awww has no "cursor" alias
  # for --transition-pos, but takes fractional positions (measured from the
  # bottom-left), so the cursor's global logical position is converted into
  # a fraction of the monitor under it. 120fps to match the docked Dells.
  cycle-wallpaper = pkgs.writeShellScriptBin "cycle-wallpaper" ''
    WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
    mapfile -t WALLS < <(find "$WALLPAPER_DIR" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" \
      -o -name "*.mp4" -o -name "*.webm" -o -name "*.mkv" -o -name "*.mov" \) | ${pkgs.coreutils}/bin/shuf)
    [ "''${#WALLS[@]}" -gt 0 ] || exit 0

    # One "<output> <transition-pos>" line per monitor.
    mapfile -t OUTPUTS < <(${pkgs.hyprland}/bin/hyprctl monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq -r \
      --argjson c "$(${pkgs.hyprland}/bin/hyprctl cursorpos -j 2>/dev/null || echo '{"x":-1,"y":-1}')" '
      def frac: [., 0.001] | max | [., 0.999] | min | tostring;
      .[]
      # width/height are physical pixels; x/y and the cursor are logical,
      # and transforms 1/3 (90/270 degrees) swap the axes.
      | . as $m
      | (if .transform % 2 == 1 then [.height, .width] else [.width, .height] end
         | map(. / $m.scale)) as [$w, $h]
      | if $c.x >= .x and $c.x < .x + $w and $c.y >= .y and $c.y < .y + $h
        then "\(.name) \(($c.x - .x) / $w | frac),\(1 - ($c.y - .y) / $h | frac)"
        else "\(.name) center"
        end')

    i=0
    for line in "''${OUTPUTS[@]}"; do
      read -r output pos <<< "$line"
      wall="''${WALLS[i % ''${#WALLS[@]}]}"
      case "$wall" in
        *.mp4 | *.webm | *.mkv | *.mov)
          ${wallpaper-video}/bin/wallpaper-video start "$output" "$wall"
          ;;
        *)
          ${wallpaper-video}/bin/wallpaper-video stop "$output"
          ${pkgs.awww}/bin/awww img -o "$output" "$wall" \
            --transition-type grow --transition-pos "''${pos:-center}" --transition-fps 120 &
          ;;
      esac
      i=$((i + 1))
    done
    wait
  '';

  # Live (video) wallpapers: one mpvpaper per output, each with an mpv IPC
  # socket in $XDG_RUNTIME_DIR/wallpaper-video/ so the others (cycle-wallpaper,
  # toggle-blackout, perf-mode, power-watch) can stop, pause and resume it.
  # mpvpaper draws above awww on the background layer; stopping it uncovers
  # whatever still awww shows. panscan=1.0 crops a video to fill the screen
  # rather than letterboxing it. Videos play only on AC with performance mode
  # off ("should-play"), and also pause themselves while a fullscreen window
  # covers them (mpvpaper -p -a FULL).
  wallpaper-video = pkgs.writeShellScriptBin "wallpaper-video" ''
    set -u
    RUNTIME="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    DIR="$RUNTIME/wallpaper-video"
    mkdir -p "$DIR"

    running() { # <output> -> prints the pid if its mpvpaper is alive
      local pid
      pid=$(cat "$DIR/$1.pid" 2>/dev/null) || return 1
      ${pkgs.gnugrep}/bin/grep -qa mpvpaper "/proc/$pid/cmdline" 2>/dev/null && echo "$pid"
    }
    stop() { # <output> [keep]: keep remembers the video (toggle-blackout)
      local pid
      if pid=$(running "$1"); then kill "$pid"; fi
      rm -f "$DIR/$1.pid" "$DIR/$1.sock"
      [ "''${2:-}" = keep ] || rm -f "$DIR/$1.path"
    }
    set_pause() { # true|false, for every running video
      local sock
      for sock in "$DIR"/*.sock; do
        [ -S "$sock" ] || continue
        echo "{\"command\":[\"set_property\",\"pause\",$1]}" |
          ${pkgs.socat}/bin/socat - "UNIX-CONNECT:$sock" >/dev/null 2>&1 || true
      done
    }
    on_ac() { # desktops/VMs without a Mains supply count as on AC
      local d found=0
      for d in /sys/class/power_supply/*; do
        [ "$(cat "$d/type" 2>/dev/null)" = Mains ] || continue
        found=1
        [ "$(cat "$d/online" 2>/dev/null)" = 1 ] && return 0
      done
      [ "$found" = 0 ]
    }
    perf_active() {
      [ "$(${pkgs.hyprland}/bin/hyprctl getoption animations:enabled -j | ${pkgs.jq}/bin/jq -r .bool)" = false ]
    }
    should_play() { on_ac && ! perf_active; }

    case "''${1:-}" in
      start) # <output> <file>
        stop "$2"
        ${pkgs.mpvpaper}/bin/mpvpaper -p -a FULL \
          -o "no-audio loop hwdec=auto panscan=1.0 input-ipc-server=$DIR/$2.sock" \
          "$2" "$3" >/dev/null 2>&1 &
        echo $! > "$DIR/$2.pid"
        printf '%s\n' "$3" > "$DIR/$2.path"
        if ! should_play; then
          for _ in $(seq 20); do [ -S "$DIR/$2.sock" ] && break; sleep 0.1; done
          set_pause true
        fi
        ;;
      stop) stop "$2" ;;
      stop-all) # [keep]
        for f in "$DIR"/*.pid; do [ -e "$f" ] && stop "$(basename "$f" .pid)" "''${2:-}"; done
        ;;
      resume-saved) # restart videos remembered by `stop-all keep`
        for f in "$DIR"/*.path; do
          [ -e "$f" ] || continue
          out=$(basename "$f" .path)
          running "$out" >/dev/null || "$0" start "$out" "$(cat "$f")"
        done
        ;;
      sync) if should_play; then set_pause false; else set_pause true; fi ;;
      should-play) if should_play; then echo yes; else echo no; fi ;;
      *) echo "usage: wallpaper-video start|stop|stop-all|resume-saved|sync|should-play" >&2; exit 1 ;;
    esac
  '';

  # Performance mode (the custom/perf waybar button, SUPER+SHIFT+F, and
  # automatic in power-saver via power-watch): blur, shadows and all
  # animations (the rotating border too) off, video wallpapers paused, audio
  # visualizer stopped. Reads Hyprland's live state rather than a
  # flag, since a config reload (e.g. hyprshell starting) silently resets it.
  # "off" turns blur/shadows back on, which is what hyprland.lua sets.
  perf-mode = pkgs.writeShellScriptBin "perf-mode" ''
    HCTL=${pkgs.hyprland}/bin/hyprctl
    CAVA=${waybar-cava}/bin/waybar-cava
    RUNTIME="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    # Set while performance mode is what silenced the visualizer, so turning
    # performance mode off never undoes a deliberate click on the bar.
    CAVA_RESUME="$RUNTIME/perf-mode-cava-resume"
    active() {
      [ "$($HCTL getoption animations:enabled -j | ${pkgs.jq}/bin/jq -r .bool)" = false ]
    }
    set_mode() {
      if [ "$1" = on ]; then v=false; else v=true; fi
      $HCTL eval "hl.config({ animations = { enabled = $v }, decoration = { blur = { enabled = $v }, shadow = { enabled = $v } } })" >/dev/null
      ${wallpaper-video}/bin/wallpaper-video sync
      if [ "$1" = on ]; then
        if [ "$($CAVA status)" = on ]; then
          $CAVA off
          touch "$CAVA_RESUME"
        fi
      elif [ -f "$CAVA_RESUME" ]; then
        $CAVA on
        rm -f "$CAVA_RESUME"
      fi
      ${pkgs.libnotify}/bin/notify-send -u low -a "Performance mode" "Performance mode $1"
    }
    case "''${1:-toggle}" in
      on | off) set_mode "$1" ;;
      toggle) if active; then set_mode off; else set_mode on; fi ;;
      status) if active; then echo on; else echo off; fi ;;
      waybar) # the custom/perf module; dim wand = effects currently off
        if active; then
          ${pkgs.jq}/bin/jq -nc '{text: "", class: "off",
            tooltip: "Performance mode: animations, blur, shadows, video wallpapers and the visualizer off (click to restore)"}'
        else
          ${pkgs.jq}/bin/jq -nc '{text: "", class: "on",
            tooltip: "Effects on (click for performance mode)"}'
        fi
        ;;
      *) echo "usage: perf-mode on|off|toggle|status|waybar" >&2; exit 1 ;;
    esac
  '';

  # Autostarted loop tying the two above to power: entering power-saver
  # turns performance mode on and leaving it turns it off (changes only, so
  # a manual SUPER+SHIFT+F sticks until the next profile change), and video
  # wallpapers are kept paused whenever they shouldn't play (battery or
  # performance mode). Pausing is re-applied every tick because mpvpaper's
  # own auto-pause can resume a video when a fullscreen window closes.
  power-watch = pkgs.writeShellScriptBin "power-watch" ''
    WV=${wallpaper-video}/bin/wallpaper-video
    PERF=${perf-mode}/bin/perf-mode
    profile() { ${pkgs.power-profiles-daemon}/bin/powerprofilesctl get 2>/dev/null || echo none; }

    # Battery warnings, since nothing else watches the charge: one normal
    # notification at 20% and one critical at 10% (critical bypasses DND and
    # sounds even then). Each fires once per discharge and rearms when the
    # charger goes back in. Hosts with no battery never match the glob, so
    # this is inert on dl-prototype and the VM.
    warned=""
    battery() { # "<capacity> <status>" for the first real battery
      local b
      for b in /sys/class/power_supply/BAT*; do
        [ -r "$b/capacity" ] || continue
        echo "$(cat "$b/capacity") $(cat "$b/status" 2>/dev/null)"
        return
      done
    }
    check_battery() {
      local cap status
      set -- $(battery)
      cap="''${1:-}"
      status="''${2:-}"
      [ -n "$cap" ] || return
      if [ "$status" != Discharging ]; then
        warned=""
      elif [ "$cap" -le 10 ] && [ "$warned" != critical ]; then
        ${pkgs.libnotify}/bin/notify-send -u critical -a Battery \
          "Battery at $cap%" "Plug in now."
        warned=critical
      elif [ "$cap" -le 20 ] && [ -z "$warned" ]; then
        ${pkgs.libnotify}/bin/notify-send -u normal -a Battery "Battery at $cap%"
        warned=low
      fi
    }

    last_profile=$(profile)
    [ "$last_profile" = power-saver ] && $PERF on
    last_play=$($WV should-play)
    while sleep 10; do
      now=$(profile)
      if [ "$now" != "$last_profile" ]; then
        if [ "$now" = power-saver ]; then
          $PERF on
        elif [ "$last_profile" = power-saver ]; then
          $PERF off
        fi
        last_profile=$now
      fi
      play=$($WV should-play)
      if [ "$play" = no ] || [ "$play" != "$last_play" ]; then
        $WV sync
      fi
      last_play=$play
      check_battery
    done
  '';

  # High-Contrast Blackout Toggle (SUPER+SHIFT+W): swaps to a solid black
  # background for glare/contrast relief, then restores whatever image was
  # showing before. `awww clear` defaults to black and `awww restore` recalls
  # the daemon's own last-displayed image, so no wallpaper path needs tracking
  # here — just whether we're currently in the blacked-out state.
  toggle-blackout = pkgs.writeShellScriptBin "toggle-blackout" ''
    # Per-user runtime dir (0700, cleared at logout), not a fixed /tmp name.
    RUNTIME="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    STATE_FILE="$RUNTIME/wallpaper-blackout"
    if [ -f "$STATE_FILE" ]; then
      ${pkgs.awww}/bin/awww restore
      ${wallpaper-video}/bin/wallpaper-video resume-saved
      rm -f "$STATE_FILE"
    else
      # Video wallpapers sit above awww, so they have to go for black to show;
      # `keep` remembers them for the restore above.
      ${wallpaper-video}/bin/wallpaper-video stop-all keep
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
    RUNTIME="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    STATE_FILE="$RUNTIME/hyprsunset-widget"

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

  # Tokyo Night LS_COLORS for eza (and anything else that reads it), sourced
  # from zsh's initContent. Generated at build time so shells don't run vivid
  # on every start.
  lsColors = pkgs.runCommand "ls-colors-tokyonight-night" { } ''
    echo "export LS_COLORS='$(${pkgs.vivid}/bin/vivid generate tokyonight-night)'" > $out
  '';

  # Waybar audio visualizer with a click on/off toggle. Replaces waybar's
  # built-in cava module, whose only click action pauses it: paused bars
  # freeze on the last frame, and with hide_on_silence there's nothing to
  # click while no audio plays. This runs the cava CLI in raw mode instead,
  # turning each frame of 0-7 levels into block characters.
  #   on:  bars while audio plays. Quiet frames show flat bars, and the
  #        module only hides after waybarCavaHideAfter seconds of them, so
  #        pauses in dialogue don't make it blink out and back.
  #   off: cava isn't running at all (no capture); a dim note icon stays so
  #        it can be clicked back on
  # Every bar runs its own `waybar-cava run`, and each registers its PID in
  # $XDG_RUNTIME_DIR/waybar-cava/. `waybar-cava toggle` flips the shared
  # state file and sends SIGUSR1 to exactly those PIDs (not a pkill pattern,
  # which would also hit any shell whose command line mentions the script).
  # On USR1 a runner kills its current job (cava pipeline or idle sleep) and
  # re-reads the state.
  waybarCavaFps = 30;
  waybarCavaHideAfter = 10; # seconds of all-zero frames before hiding
  waybarCavaConf = pkgs.writeText "waybar-cava.conf" ''
    [general]
    framerate = ${toString waybarCavaFps}
    bars = 12
    autosens = 1
    lower_cutoff_freq = 50
    higher_cutoff_freq = 10000
    # cava stops writing frames after this long of digital silence (e.g.
    # playback paused). Kept above waybarCavaHideAfter so the hide countdown
    # always finishes first; otherwise frames could stop before it did and
    # leave flat bars showing for the whole pause.
    sleep_timer = ${toString (waybarCavaHideAfter * 2)}

    [input]
    method = pipewire
    source = auto

    [output]
    method = raw
    raw_target = /dev/stdout
    data_format = ascii
    ascii_max_range = 7
    bar_delimiter = 59
    channels = stereo

    [smoothing]
    noise_reduction = 77
  '';
  waybar-cava = pkgs.writeShellScriptBin "waybar-cava" ''
    OFF="''${XDG_STATE_HOME:-$HOME/.local/state}/waybar-cava-off"
    RUNDIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/waybar-cava"
    PKILL="${pkgs.procps}/bin/pkill"

    if [ "$1" = "status" ]; then
      if [ -f "$OFF" ]; then echo off; else echo on; fi
      exit 0
    fi

    # on/off are for perf-mode, which needs to force a state rather than flip
    # whatever the current one is.
    if [ "$1" = "toggle" ] || [ "$1" = "on" ] || [ "$1" = "off" ]; then
      case "$1" in
        on) rm -f "$OFF" ;;
        off)
          mkdir -p "$(dirname "$OFF")"
          touch "$OFF"
          ;;
        toggle)
          if [ -f "$OFF" ]; then
            rm -f "$OFF"
          else
            mkdir -p "$(dirname "$OFF")"
            touch "$OFF"
          fi
          ;;
      esac
      # A runner killed with SIGKILL leaves its PID file behind, and USR1's
      # default action terminates, so only signal PIDs that are still a
      # waybar-cava process.
      for f in "$RUNDIR"/*; do
        [ -e "$f" ] || continue
        pid="''${f##*/}"
        if ${pkgs.gnugrep}/bin/grep -qa waybar-cava "/proc/$pid/cmdline" 2>/dev/null; then
          kill -USR1 "$pid"
        else
          rm -f "$f"
        fi
      done
      exit 0
    fi

    # `run` (the waybar exec): one JSON object per line until killed.
    OFF_JSON=$(${pkgs.jq}/bin/jq -nc \
      '{text: "\uf001", class: "off", tooltip: "Visualizer off (click to turn on)"}')
    mkdir -p "$RUNDIR"
    touch "$RUNDIR/$$"

    # The cava pipeline runs in a background subshell so `wait` (unlike a
    # foreground pipeline) is interrupted by USR1 straight away. Killing the
    # subshell's children as well stops cava itself, even while it's in its
    # silent sleep and not writing (so SIGPIPE would never reach it).
    JOB=""
    stop_job() {
      if [ -n "$JOB" ]; then
        $PKILL -P "$JOB" 2>/dev/null
        kill "$JOB" 2>/dev/null
      fi
    }
    trap stop_job USR1
    trap 'stop_job; rm -f "$RUNDIR/$$"; exit 0' TERM INT HUP
    trap 'rm -f "$RUNDIR/$$"' EXIT

    while true; do
      if [ -f "$OFF" ]; then
        STATE=off
        echo "$OFF_JSON"
        sleep infinity &
        JOB=$!
      else
        STATE=on
        # All-zero frames count toward the hide delay and render as flat
        # bars until it's reached; then one empty text hides the module.
        # Anything that isn't a frame is dropped: when cava fails (e.g. it
        # can't reach PipeWire) it still writes a terminal-title escape.
        (
          ${pkgs.cava}/bin/cava -p ${waybarCavaConf} 2>/dev/null |
            ${pkgs.gawk}/bin/awk -v hide=${toString (waybarCavaFps * waybarCavaHideAfter)} '
              BEGIN { split("▁ ▂ ▃ ▄ ▅ ▆ ▇ █", glyph, " ") }
              !/^[0-9;]*$/ { next }
              { gsub(/;/, "") }
              /^0*$/ {
                quiet++
                if (quiet == hide) { print "{\"text\": \"\"}"; fflush() }
                if (quiet >= hide) next
              }
              !/^0*$/ { quiet = 0 }
              {
                bars = ""
                for (i = 1; i <= length($0); i++) bars = bars glyph[substr($0, i, 1) + 1]
                printf "{\"text\": \"%s\", \"class\": \"on\", \"tooltip\": \"Visualizer on (click to turn off)\"}\n", bars
                fflush()
              }
            '
        ) &
        JOB=$!
      fi
      wait "$JOB"
      stop_job
      JOB=""
      # The job ended without a toggle (e.g. cava failed): don't spin.
      if { [ "$STATE" = on ] && [ ! -f "$OFF" ]; } || { [ "$STATE" = off ] && [ -f "$OFF" ]; }; then
        sleep 2
      fi
    done
  '';

  # Notification sounds, run by swaync's `scripts` (services.swaync below)
  # per urgency: a soft chime for normal, a warning tone for critical,
  # nothing for low. swaync runs scripts even in do-not-disturb, so normal
  # ones check it here; critical ones sound regardless, since their popups
  # bypass DND too. Always exits 0: swaync posts a "script failed"
  # notification otherwise, which would run this again and loop.
  #
  # KDE's ocean theme rather than freedesktop's: its tones sit around
  # 350-500Hz where freedesktop's message-new-instant is centred near 900Hz
  # and peaks at 466Hz, loud enough to distort the Framework's speakers with
  # the sink up. Volume is a stream gain on top of the sink volume, so this
  # is quiet at any sink setting; raise it here rather than swapping files.
  notifySoundVolume = "0.10";
  notify-sound = pkgs.writeShellScript "notify-sound" ''
    sounds=${pkgs.kdePackages.ocean-sound-theme}/share/sounds/ocean/stereo
    case "$1" in
      critical) sound=dialog-warning-auth ;;
      normal)
        if [ "$(${pkgs.swaynotificationcenter}/bin/swaync-client -D -sw 2>/dev/null)" = true ]; then
          exit 0
        fi
        sound=message-new-email
        ;;
      *) exit 0 ;;
    esac
    ${pkgs.pipewire}/bin/pw-play --volume ${notifySoundVolume} "$sounds/$sound.oga" || true
    exit 0
  '';

  # hyprlock label helpers. Labels are Pango markup, so text from outside
  # (track titles) has &, < and > escaped. Each prints nothing when there's
  # nothing to show, which leaves the label empty.
  hyprlock-nowplaying = pkgs.writeShellScript "hyprlock-nowplaying" ''
    PCTL="${pkgs.playerctl}/bin/playerctl"
    case "$($PCTL status 2>/dev/null)" in
      Playing) icon=$'\uf04b' ;;
      Paused) icon=$'\uf04c' ;;
      *) exit 0 ;;
    esac
    track=$($PCTL metadata --format '{{title}}  ·  {{artist}}' 2>/dev/null |
      ${pkgs.gnused}/bin/sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    printf '%s  %s\n' "$icon" "$track"
  '';
  hyprlock-battery = pkgs.writeShellScript "hyprlock-battery" ''
    for b in /sys/class/power_supply/BAT*; do
      [ -r "$b/capacity" ] || continue
      cap=$(cat "$b/capacity")
      if [ "$cap" -ge 85 ]; then icon=$'\uf240'
      elif [ "$cap" -ge 60 ]; then icon=$'\uf241'
      elif [ "$cap" -ge 35 ]; then icon=$'\uf242'
      elif [ "$cap" -ge 10 ]; then icon=$'\uf243'
      else icon=$'\uf244'; fi
      [ "$(cat "$b/status")" = Charging ] && icon="$icon "$'\uf0e7'
      printf '%s  %s%%\n' "$icon" "$cap"
      exit 0
    done
  '';

  # Holds a logind idle inhibitor while audio is actually playing, so a movie
  # or a long track doesn't get dimmed at 4m30s and locked at 5m. hypridle
  # respects systemd idle inhibitors (its ignore_systemd_inhibit defaults to
  # false and isn't set below), so this needs no hypridle config of its own —
  # and it suppresses the 20-minute suspend listener too.
  #
  # "Playing" is a PipeWire output stream in the `running` state: a paused
  # player drops out of running, so pausing a video re-arms the lock within a
  # tick. The notification blips are excluded by name so a chime can't buy
  # itself 30 seconds of inhibit. Capture streams (the cava visualizer) are a
  # different media.class and never match.
  media-inhibit = pkgs.writeShellScriptBin "media-inhibit" ''
    RUNTIME="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    PIDFILE="$RUNTIME/media-inhibit.pid"

    playing() {
      [ -n "$(${pkgs.pipewire}/bin/pw-dump 2>/dev/null | ${pkgs.jq}/bin/jq -r '
        .[] | select(.info.props."media.class" == "Stream/Output/Audio")
            | select(.info.state == "running")
            | select(.info.props."application.name" != "pw-play")
            | .id' | head -1)" ]
    }
    # Same PID-file discipline as the other scripts here: verify the process
    # is still ours before signalling it, never pkill a command-line pattern.
    held() {
      local pid
      pid=$(cat "$PIDFILE" 2>/dev/null) || return 1
      ${pkgs.gnugrep}/bin/grep -qa systemd-inhibit "/proc/$pid/cmdline" 2>/dev/null && echo "$pid"
    }
    release() {
      local pid
      if pid=$(held); then kill "$pid"; fi
      rm -f "$PIDFILE"
    }
    trap 'release; exit 0' TERM INT HUP
    # An inhibitor outlives the watcher that started it, so a previous run
    # killed outright (SIGKILL, a logout race) would otherwise leave one
    # blocking the lock forever. Drop any it left behind before starting.
    release

    while true; do
      if playing; then
        if ! held >/dev/null; then
          ${pkgs.systemd}/bin/systemd-inhibit --what=idle --who=media-inhibit \
            --why="audio playing" ${pkgs.coreutils}/bin/sleep infinity &
          echo $! > "$PIDFILE"
        fi
      else
        release
      fi
      # Backgrounded so the TERM trap runs now rather than after the sleep:
      # bash defers a trap until the running foreground command returns, and
      # a 30s delay there is 30s of not locking after logout.
      sleep 30 &
      wait $!
    done
  '';

  # hypridle's dim-before-lock step. Saves the current brightness in the
  # runtime dir and restores it on input, instead of brightnessctl -s/-r,
  # whose save file is a fixed path under the shared /tmp.
  idle-dim = pkgs.writeShellScriptBin "idle-dim" ''
    RUNTIME="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    SAVE="$RUNTIME/brightness-before-dim"
    BCTL=${pkgs.brightnessctl}/bin/brightnessctl
    case "$1" in
      dim)
        $BCTL get > "$SAVE" && $BCTL -q set 10%
        ;;
      restore)
        [ -s "$SAVE" ] && $BCTL -q set "$(cat "$SAVE")"
        rm -f "$SAVE"
        ;;
      *)
        echo "usage: idle-dim dim|restore" >&2
        exit 1
        ;;
    esac
  '';

  # Daily update check (update-check timer below). Works out what
  # `nix flake update` would change by writing the result to a temp file,
  # so /etc/nixos is never touched, and if anything is newer, asks with a
  # notification. Nothing changes unless you click "Update now".
  update-check = pkgs.writeShellScriptBin "update-check" ''
    set -u
    export PATH=${
      lib.makeBinPath [
        pkgs.nix
        pkgs.git
        pkgs.jq
        pkgs.coreutils
      ]
    }:$PATH
    # No network yet (e.g. just woke): try again tomorrow, quietly.
    ${pkgs.networkmanager}/bin/nm-online -q -t 120 || exit 0

    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    if ! nix flake update --flake /etc/nixos --output-lock-file "$tmp/new.lock" >"$tmp/log" 2>&1; then
      echo "update check failed:"; cat "$tmp/log"
      exit 0
    fi

    changes=$(jq -r --slurpfile old /etc/nixos/flake.lock '
      .nodes | to_entries[]
      | select(.value.locked.rev?)
      | .key as $k
      | ($old[0].nodes[$k].locked // {}) as $o
      | select($o.rev != .value.locked.rev)
      | "\($k): \(($o.lastModified // 0) | todate | .[5:10]) → \(.value.locked.lastModified | todate | .[5:10])"
    ' "$tmp/new.lock")
    if [ -z "$changes" ]; then
      echo "up to date"
      exit 0
    fi
    echo "updates available:"; echo "$changes"

    # --wait blocks until you pick an action or dismiss it; a popup that
    # times out stays in swaync's notification center, still answerable.
    action=$(${pkgs.libnotify}/bin/notify-send -a "System updates" -i system-software-update \
      -A update="Update now" -A later="Later" --wait \
      "Updates ready" "$changes")
    if [ "$action" = update ]; then
      ${ghosttyBin} --title="System update" -e update-apply
    fi
  '';

  # The "Update now" terminal: updates flake.lock, then `nh os switch --ask`,
  # which shows the package diff and asks before activating. Declining
  # puts flake.lock back.
  update-apply = pkgs.writeShellScriptBin "update-apply" ''
    set -u
    cd /etc/nixos || exit 1
    pause() { read -r -n1 -s -p "Press any key to close."; echo; }

    if ! ${pkgs.git}/bin/git diff --quiet -- flake.lock; then
      echo "flake.lock has uncommitted changes; commit or discard them first."
      pause; exit 1
    fi

    ${pkgs.nix}/bin/nix flake update || { pause; exit 1; }
    if ${pkgs.nh}/bin/nh os switch /etc/nixos -H ${flakeAttr} --ask; then
      echo
      read -r -p "Commit flake.lock? [y/N] " answer
      case "$answer" in
        y | Y) ${pkgs.git}/bin/git commit -m "Update flake.lock" -- flake.lock ;;
        *) echo "Left uncommitted: git -C /etc/nixos commit -m 'Update flake.lock' flake.lock" ;;
      esac
    else
      ${pkgs.git}/bin/git checkout -- flake.lock
      echo "Not applied; flake.lock restored."
    fi
    pause
  '';

  # Opens Grafana on a monitoring host (dl-prototype, utm-nixos) through an
  # SSH tunnel: Grafana listens only on that host's 127.0.0.1
  # (modules/services/monitoring.nix). Ctrl+C closes the tunnel.
  grafana-tunnel = pkgs.writeShellScriptBin "grafana-tunnel" ''
    host="''${1:?usage: grafana-tunnel <host> [local-port]}"
    port="''${2:-3000}"
    echo "Grafana on $host -> http://localhost:$port (Ctrl+C to close)"
    (sleep 2 && ${pkgs.xdg-utils}/bin/xdg-open "http://localhost:$port") &
    exec ssh -N -L "$port:localhost:3000" "$host"
  '';

  # Grab text off the screen (SUPER+SHIFT+T): select a region, OCR it, put the
  # result on the clipboard. Same grimblast selection as the screenshot bind,
  # with --freeze so a video frame or a menu can be captured mid-motion.
  #
  # The OCR result is untrusted text and swaync renders bodies as Pango
  # markup, so the preview escapes &, < and > (see docs/security.md); the
  # clipboard gets the text unmodified. wl-copy under `umask 077` matches the
  # other clipboard callers, keeping cliphist's db private.
  ocr-region = pkgs.writeShellScriptBin "ocr-region" ''
    text=$(${pkgs.grimblast}/bin/grimblast --freeze save area - 2>/dev/null |
      ${pkgs.tesseract}/bin/tesseract -l eng - - 2>/dev/null |
      ${pkgs.gnused}/bin/sed -e 's/[[:space:]]*$//' -e '/./,$!d')
    if [ -z "''${text//[[:space:]]/}" ]; then
      ${pkgs.libnotify}/bin/notify-send -u low -a OCR "No text found"
      exit 0
    fi
    umask 077
    printf '%s' "$text" | ${pkgs.wl-clipboard}/bin/wl-copy
    preview=$(printf '%s' "$text" | ${pkgs.coreutils}/bin/head -c 120 |
      ${pkgs.gnused}/bin/sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
    ${pkgs.libnotify}/bin/notify-send -u low -a OCR "Copied $(printf '%s' "$text" | ${pkgs.coreutils}/bin/wc -c) chars" "$preview"
  '';

  # Screen recording toggle (SUPER+ALT+R): mirrors the grimblast/swappy
  # screenshot pattern above, but for video. First call starts wf-recorder
  # in the background against the whole output and stashes its PID; second
  # call sends SIGINT (wf-recorder's clean-stop signal, finalizes the mp4)
  # and clears the PID file. notify-send gives a themed start/stop toast
  # through whatever notification daemon is running (swaync here).
  toggle-recording = pkgs.writeShellScriptBin "toggle-recording" ''
    RUNTIME="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    PIDFILE="$RUNTIME/wf-recorder.pid"
    OUT_DIR="$HOME/Videos/Recordings"
    mkdir -p "$OUT_DIR"

    # Only signal the PID if it's still wf-recorder: a stale file (e.g. the
    # recorder crashed) could otherwise name some unrelated process.
    PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$PID" ] && ${pkgs.gnugrep}/bin/grep -qa wf-recorder "/proc/$PID/cmdline" 2>/dev/null; then
      kill -INT "$PID"
      rm -f "$PIDFILE"
      ${pkgs.libnotify}/bin/notify-send "Screen Recording" "Stopped"
    else
      FILE="$OUT_DIR/recording-$(date +%Y%m%d-%H%M%S).mp4"
      ${pkgs.wf-recorder}/bin/wf-recorder -f "$FILE" >"$RUNTIME/wf-recorder.log" 2>&1 &
      echo $! > "$PIDFILE"
      ${pkgs.libnotify}/bin/notify-send "Screen Recording" "Started: $FILE"
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
    waybar-cava
    grafana-tunnel
    wallpaper-video
    perf-mode
    power-watch
    media-inhibit
    ocr-region
    update-check
    update-apply
    idle-dim
    pkgs.power-profiles-daemon # powerprofilesctl CLI, used by waybar-power-profile above
    # Modern CLI
    pkgs.ripgrep
    pkgs.eza
    pkgs.fd
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
    pkgs.mpv # Video/audio player, for media opened from Thunar
    pkgs.wf-recorder # Screen recording backend for toggle-recording (SUPER+ALT+R)
    pkgs.wofi-emoji # Emoji picker (SUPER+period); types the pick via wtype and copies it
    pkgs.playerctl # Media keys (Play/Next/Prev in hyprland.lua)
    pkgs.hyprshell # SUPER+Tab overview + launcher, ALT+Tab switcher (autostarted in hyprland.lua)
    # Password manager, launched without the qt5ct platform-theme plugin:
    # qt5ct has no nixpkgs maintainer, and a platform theme is loaded into
    # the app's own process. With the two variables unset KeePassXC loads
    # only Qt's own plugins and uses its built-in Dark theme
    # ([GUI] ApplicationTheme=dark in keepassxc.ini). The .desktop Exec is
    # a bare `keepassxc`, so launchers and xdg-open pick up this wrapper.
    (pkgs.symlinkJoin {
      name = "keepassxc-without-qtct";
      paths = [ pkgs.keepassxc ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/keepassxc \
          --unset QT_QPA_PLATFORMTHEME \
          --unset QT_STYLE_OVERRIDE
      '';
    })
    pkgs.resources # GTK4/libadwaita system monitor (GUI complement to bottom/htop)
    pkgs.rclone # CLI sync/mount for cloud storage remotes
    pkgs.gnome-firmware # GUI firmware updater, complements fwupd (see framework host)
    pkgs.syncthingtray # Waybar tray icon/control for the syncthing service
    # (modules/services/syncthing.nix)

    # GIS. Kept as two separate packages because QGIS's native GRASS plugin
    # (qgis-ltr.override { withGrass = true; }) isn't in the binary cache
    # and would build QGIS from source; QGIS's Processing toolbox runs GRASS
    # algorithms through the separate `grass` on PATH instead.
    pkgs.qgis-ltr # QGIS long-term release (3.44)
    pkgs.grass # GRASS GIS (standalone GUI + CLI)

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
    gtk3.extraCss = gtkNamedColors;
    gtk4.extraCss = gtkNamedColors + gtkCssVariables;
  };

  # Qt Theming
  # Qt apps (syncthingtray, QGIS; KeePassXC opts out, see its wrapper) get
  # the palette through qt5ct/qt6ct: a color scheme built from the Tokyo
  # Night values, applied with the Fusion style (Adwaita's Qt style draws
  # its own grays and ignores the palette).
  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "Fusion";
    qt5ctSettings = qtctSettings;
    qt6ctSettings = qtctSettings;
  };

  # XDG Desktop Portal Color Scheme
  # Declarative source of truth for GTK/libadwaita theming — no need to
  # re-run gsettings at every Hyprland startup (see hyprland.lua autostart).
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
  # Pulled into every bar in config via "include".
  xdg.configFile."waybar/modules.jsonc".source = ./waybar/modules.jsonc;
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
  xdg.configFile."ghostty/shaders" = {
    source = ./ghostty/shaders;
    recursive = true;
  };
  # hyprshell probes config.ron, .toml, .json, .json5 in that order, so this
  # is picked up as long as no config.ron exists. Strict JSON (valid JSON5)
  # so scripts/check-keybinds.sh can read its binds with jq.
  xdg.configFile."hyprshell/config.json".source = ./hyprshell/config.json;
  xdg.configFile."hyprshell/styles.css".source = ./hyprshell/styles.css;
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

      # Explicit fade: hyprlock 0.9 already fades in by default (0.8s, default
      # curve); this makes it a quicker ease-out.
      animations = {
        enabled = true;
        bezier = [ "easeOut, 0.16, 1, 0.3, 1" ];
        animation = [
          "fadeIn, 1, 5, easeOut"
          "fadeOut, 1, 5, easeOut"
        ];
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
        {
          # Weather, top-left, orange like waybar's weather module. Same
          # wttr.in line; fetched once at lock and every 30 minutes. @html
          # escapes it: labels are Pango markup and this text is remote.
          text = "cmd[update:1800000] ${waybar-weather}/bin/waybar-weather | ${pkgs.jq}/bin/jq -r '.text | @html'";
          color = "rgb(255, 158, 100)";
          font_size = 16;
          font_family = "JetBrainsMono Nerd Font";
          position = "30, -30";
          halign = "left";
          valign = "top";
        }
        {
          # Battery, top-right, green like the charging state in waybar.
          # Empty on hosts without a battery.
          text = "cmd[update:30000] ${hyprlock-battery}";
          color = "rgb(158, 206, 106)";
          font_size = 16;
          font_family = "JetBrainsMono Nerd Font";
          position = "-30, -30";
          halign = "right";
          valign = "top";
        }
        {
          # Now playing, bottom center; empty when no player is active.
          text = "cmd[update:2000] ${hyprlock-nowplaying}";
          color = "rgb(192, 202, 245)";
          font_size = 14;
          font_family = "JetBrainsMono Nerd Font";
          position = "0, 40";
          halign = "center";
          valign = "bottom";
        }
      ];
    };
  };

  # Notifications + notification center (SUPER+N, waybar bell). Its HM unit
  # is Type=dbus with BusName org.freedesktop.Notifications, so D-Bus starts
  # it on the first notification even though graphical-session.target is
  # never reached here. Config and style are tested files in ./swaync.
  services.swaync = {
    enable = true;
    settings = lib.importJSON ./swaync/config.json // {
      scripts = {
        sound-normal = {
          urgency = "Normal";
          exec = "${notify-sound} normal";
        };
        sound-critical = {
          urgency = "Critical";
          exec = "${notify-sound} critical";
        };
      };
    };
    style = ./swaync/style.css;
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
          # Dim to 10% 30s before the lock below, as a warning: any input
          # before then restores the saved brightness (idle-dim above keeps
          # it in the runtime dir). Only affects backlit panels
          # (framework's eDP-1); external monitors aren't touched.
          timeout = 270;
          on-timeout = "${idle-dim}/bin/idle-dim dim";
          on-resume = "${idle-dim}/bin/idle-dim restore";
        }
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

      # Right side: how long the last command took (only when over 2s) and
      # the time, 12-hour like the waybar clock. Shown on the prompt's last
      # line, next to the ❯.
      right_format = "$cmd_duration$time";
      cmd_duration = {
        min_time = 2000;
        format = "[ $duration]($style) ";
        style = "#ff9e64";
      };
      time = {
        disabled = false;
        format = "[$time]($style)";
        time_format = "%I:%M %p";
        style = "#a9b1d6";
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
      # Nothing claimed web links before, so hyprshell's web-search plugin
      # (and anything else going through xdg-open) fell back to guessing.
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
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
  # git itself was configured only by the hand-written ~/.gitconfig (name,
  # email, safe.directory), which git still reads after this file; HM adds
  # ~/.config/git/config for delta. Side-by-side diffs with line numbers,
  # tokyonight syntax colors (the bat theme above) and tokyonight's own
  # delta diff colors via include.
  programs.git = {
    enable = true;
    includes = [
      { path = "${pkgs.vimPlugins.tokyonight-nvim}/extras/delta/tokyonight_night.gitconfig"; }
    ];
  };
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      side-by-side = true;
      line-numbers = true;
      navigate = true; # n / N jump between files
      syntax-theme = "tokyonight_night";
      file-style = "bold #7aa2f7";
      file-decoration-style = "#7aa2f7 ul";
      hunk-header-decoration-style = "#414868 box";
    };
  };

  programs.fzf = {
    enable = true;
    # Tokyo Night, using the repo's palette (see docs/desktop.md) rather than
    # tokyonight.nvim's fzf extra, which brings in extra colors. bg -1 keeps
    # Ghostty's translucent background; bg+ is Ghostty's selection color.
    colors = {
      fg = "#c0caf5";
      "fg+" = "#c0caf5";
      bg = "-1";
      "bg+" = "#3b3d4d";
      hl = "#7dcfff";
      "hl+" = "#7dcfff";
      info = "#9ece6a";
      prompt = "#7aa2f7";
      pointer = "#ff9e64";
      marker = "#9ece6a";
      spinner = "#bb9af7";
      header = "#ff9e64";
      border = "#7aa2f7";
    };
  };

  # `cat` is aliased to bat below. The theme is tokyonight.nvim's own
  # sublime export, the same colorscheme LazyVim uses.
  programs.bat = {
    enable = true;
    config.theme = "tokyonight_night";
    themes.tokyonight_night = {
      src = pkgs.vimPlugins.tokyonight-nvim;
      file = "extras/sublime/tokyonight_night.tmTheme";
    };
  };

  # btm (waybar's cpu/memory click action).
  programs.bottom = {
    enable = true;
    settings.styles = {
      cpu = {
        all_entry_color = "#7aa2f7";
        avg_entry_color = "#ff9e64";
        cpu_core_colors = [
          "#7aa2f7"
          "#9ece6a"
          "#bb9af7"
          "#7dcfff"
          "#ff9e64"
          "#e0af68"
          "#f7768e"
        ];
      };
      memory = {
        ram_color = "#bb9af7"; # Purple, matches waybar's memory module
        cache_color = "#7dcfff";
        swap_color = "#ff9e64";
        gpu_colors = [
          "#7aa2f7"
          "#9ece6a"
          "#ff9e64"
        ];
      };
      network = {
        rx_color = "#9ece6a";
        tx_color = "#7aa2f7";
        rx_total_color = "#9ece6a";
        tx_total_color = "#7aa2f7";
      };
      battery = {
        high_battery_color = "#9ece6a";
        medium_battery_color = "#ff9e64";
        low_battery_color = "#f7768e";
      };
      tables.headers = {
        color = "#7aa2f7";
        bold = true;
      };
      graphs = {
        graph_color = "#414868";
        legend_text.color = "#a9b1d6";
      };
      widgets = {
        border_color = "#414868";
        selected_border_color = "#7aa2f7";
        widget_title.color = "#c0caf5";
        text.color = "#c0caf5";
        selected_text = {
          color = "#1a1b26";
          bg_color = "#7aa2f7";
        };
        disabled_text.color = "#414868";
      };
    };
  };

  # PDF viewer for docs opened from Thunar. tokyonight.nvim's zathura export
  # themes the UI; recolor also darkens the pages themselves (Ctrl+R toggles
  # back to the original colors).
  programs.zathura = {
    enable = true;
    options.recolor = true;
    extraConfig = "include ${pkgs.vimPlugins.tokyonight-nvim}/extras/zathura/tokyonight_night.zathurarc";
  };
  # yazi: terminal file manager with image/PDF/video previews in Ghostty
  # (kitty graphics protocol). pkgs.yazi already wraps its preview helpers
  # (ffmpeg, poppler, ImageMagick, chafa, 7-Zip, fd, rg, fzf, zoxide).
  # `y` opens it and cd's the shell to wherever you quit.
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
  };
  # tokyonight.nvim's own yazi export, like bat/zathura/delta above.
  # programs.yazi only writes theme.toml when its `theme` is set. The export
  # still writes [filetype] rules as `{ name = ... }`, which yazi 26 rejects
  # ("at least one of `url` or `mime` must be specified", and the whole theme
  # is dropped); the key is `url` now.
  xdg.configFile."yazi/theme.toml".source = pkgs.runCommand "yazi-tokyonight-night.toml" { } ''
    sed 's/{ name = /{ url = /' \
      ${pkgs.vimPlugins.tokyonight-nvim}/extras/yazi/tokyonight_night.toml > $out
  '';
  programs.zoxide.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      # Ghost text in the palette's muted slate (Ghostty's bright black).
      highlight = "fg=#414868";
    };
    # Tokyo Night: commands blue, keywords purple, strings green, options
    # orange, unknown commands red.
    syntaxHighlighting = {
      enable = true;
      styles = {
        default = "fg=#c0caf5";
        unknown-token = "fg=#f7768e";
        reserved-word = "fg=#bb9af7";
        alias = "fg=#7aa2f7";
        suffix-alias = "fg=#7aa2f7";
        global-alias = "fg=#7aa2f7";
        builtin = "fg=#7aa2f7";
        function = "fg=#7aa2f7";
        command = "fg=#7aa2f7";
        precommand = "fg=#7aa2f7,italic";
        hashed-command = "fg=#7aa2f7";
        arg0 = "fg=#7aa2f7";
        commandseparator = "fg=#7dcfff";
        redirection = "fg=#7dcfff";
        globbing = "fg=#7dcfff";
        history-expansion = "fg=#7dcfff";
        path = "fg=#c0caf5,underline";
        single-hyphen-option = "fg=#ff9e64";
        double-hyphen-option = "fg=#ff9e64";
        single-quoted-argument = "fg=#9ece6a";
        double-quoted-argument = "fg=#9ece6a";
        dollar-quoted-argument = "fg=#9ece6a";
        back-quoted-argument = "fg=#bb9af7";
        dollar-double-quoted-argument = "fg=#7dcfff";
        back-double-quoted-argument = "fg=#7dcfff";
        comment = "fg=#414868,italic";
      };
    };

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
      source ${lsColors}
      # fzf and atuin both bind CTRL+R from their own init snippets, and which
      # one wins depends on the order Home Manager emits them. Bind it here,
      # last, so it's atuin either way. fzf keeps CTRL+T and ALT+C.
      bindkey '^R' atuin-search
      if [[ $TERM != "dumb" ]]; then
        fastfetch
      fi
    '';
  };

  # Shell history in SQLite with a fuzzy search UI on CTRL+R, replacing zsh's
  # plain reverse search. Local only: no account, no sync, and update_check
  # off, so it never talks to the network. The zsh history file above still
  # gets written, so nothing is lost if atuin is removed.
  #
  # --disable-up-arrow keeps Up as plain zsh history (same key, same
  # behaviour as before); only CTRL+R changes. enter_accept = false puts the
  # chosen command on the prompt for editing rather than running it straight
  # from the picker.
  programs.atuin = {
    enable = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      auto_sync = false;
      update_check = false;
      style = "compact";
      inline_height = 20;
      show_preview = true;
      enter_accept = false;
      filter_mode = "global";
      theme.name = "tokyonight";
    };
    # Same palette as the rest of the rice (see docs/desktop.md); atuin's
    # own themes are TOML files under ~/.config/atuin/themes/.
    themes.tokyonight = {
      theme.name = "tokyonight";
      colors = {
        AlertInfo = "#9ece6a";
        AlertWarn = "#ff9e64";
        AlertError = "#f7768e";
        Annotation = "#7dcfff";
        Base = "#c0caf5";
        Guidance = "#414868";
        Important = "#bb9af7";
        Title = "#7aa2f7";
        Muted = "#565f89";
      };
    };
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
    # The catppuccin cursor package also ships a hyprcursor (vector) version.
    # Without these, Hyprland scales the bitmap XCursor to the panel's 1.175
    # and the Dells' 1.5, which blurs it. Taken from gtk.cursorTheme so the
    # theme and size have one source.
    HYPRCURSOR_THEME = config.gtk.cursorTheme.name;
    HYPRCURSOR_SIZE = toString config.gtk.cursorTheme.size;
  };

  # Daily "are updates ready?" check. A user timer (timers.target), so it
  # doesn't depend on graphical-session.target; the user manager already
  # has the Wayland session's variables, which the notification and the
  # "Update now" terminal need. Missed while asleep: runs at the next wake.
  systemd.user.services.update-check = {
    Unit.Description = "Check for NixOS updates and ask";
    Service = {
      Type = "oneshot";
      ExecStart = "${update-check}/bin/update-check";
    };
  };
  systemd.user.timers.update-check = {
    Unit.Description = "Daily NixOS update check";
    Timer = {
      OnCalendar = "*-*-* 10:00:00";
      RandomizedDelaySec = "10min";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  home.activation.createScreenshotsDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.home.homeDirectory}/Pictures/Screenshots
  '';
}
