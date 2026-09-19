-- Migrated from hyprland.conf (2026-09-15): Hyprland 0.56+ treats the old
-- .conf/hyprlang syntax as legacy and looks for hyprland.lua first.
-- See https://wiki.hypr.land/configuring/

-- The hostname placeholder below is substituted by home.nix at build time
-- (osConfig.networking.hostName), since this same file is shared, unmodified,
-- across all three hosts. Only "framework" has its exact panel mode/scale
-- tuned below; dl-prototype and utm-nixos fall back to Hyprland's own
-- auto-detection rather than inheriting Framework's HiDPI panel mode, which
-- wouldn't exist on them.
if "@HOSTNAME@" == "framework" then
  -- Scoped to eDP-1: output = "" would also force the panel's mode/scale onto
  -- anything plugged into the dock.
  hl.monitor({
    output = "eDP-1",
    mode = "2256x1504@60",
    position = "0x0",
    scale = 1.175, -- 2256x1504 panel; 1.175 is the exact divisor Hyprland wants (-> 1920x1280 logical)
  })
  -- CalDigit TS4 desk setup: laptop | Dell landscape | Dell portrait. Matched
  -- by serial (desc:), not DP-N, since the connector names depend on which
  -- dock port each cable is in. Positions are in logical pixels: 4K / 1.5 =
  -- 2560x1440, so the landscape Dell starts at the laptop's 1920 logical width
  -- and the portrait one at 1920 + 2560. transform = 3 is 270°.
  hl.monitor({
    output = "desc:Dell Inc. DELL S2725QC 10VD464",
    mode = "3840x2160@120",
    position = "1920x0",
    scale = 1.5,
  })
  hl.monitor({
    output = "desc:Dell Inc. DELL S2725QC 83VD464",
    mode = "3840x2160@120",
    position = "4480x0",
    scale = 1.5,
    transform = 3,
  })
  -- Any other display (projector, hotel TV): Hyprland's own guess.
  hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
  })
else
  hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
  })
end

hl.config({
  xwayland = {
    force_zero_scaling = true,
  },

  input = {
    kb_layout = "us",
    kb_options = "ctrl:nocaps",
    follow_mouse = 1,
    touchpad = {
      natural_scroll = true,
      tap_to_click = true,
    },
  },

  general = {
    gaps_in = 2,
    -- Matches waybar's margin-left/margin-right (8, see waybar/config.jsonc)
    -- so tiled windows' outer edge lines up with the bar instead of
    -- extending past it.
    gaps_out = 8,
    border_size = 2,
    col = {
      active_border = { colors = { "rgba(7aa2f7ee)", "rgba(9ece6aee)" }, angle = 45 },
      inactive_border = "rgba(1a1a20aa)",
    },
    layout = "dwindle",
  },

  decoration = {
    -- Same 12px radius as waybar, wofi, wlogout and dunst.
    rounding = 12,
    -- Default is 0.2, too faint to notice behind the scratchpad (SUPER+S).
    dim_special = 0.4,
    active_opacity = 0.9,
    inactive_opacity = 0.8,
    -- Strong enough that the 0.9/0.8 opacity above reads as frosted glass
    -- rather than the wallpaper showing through sharp.
    blur = {
      enabled = true,
      size = 6,
      passes = 3,
      vibrancy = 0.17,
      noise = 0.02,
    },
    -- Same near-black as waybar's bar background and Ghostty's background.
    shadow = {
      enabled = true,
      range = 20,
      render_power = 3,
      color = "rgba(0a0b10cc)",
    },
  },

  animations = {
    enabled = true,
  },

  -- Tabbed groups (SUPER+G): active group gets the same blue->green border
  -- as a focused window, and the tab bar uses the palette's blue on the
  -- module background.
  group = {
    col = {
      border_active = { colors = { "rgba(7aa2f7ee)", "rgba(9ece6aee)" }, angle = 45 },
      border_inactive = "rgba(1a1a20aa)",
    },
    groupbar = {
      font_family = "JetBrainsMono Nerd Font",
      font_size = 10,
      height = 18,
      gradients = true,
      rounding = 6,
      gradient_rounding = 6,
      indicator_height = 0,
      text_color = "rgba(c0caf5ff)",
      col = {
        active = "rgba(7aa2f7cc)",
        inactive = "rgba(1a1b26cc)",
      },
    },
  },

  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
  },
})

-- Animations
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default", style = "slidefade 20%" })
-- The scratchpad (SUPER+S) lives on a special workspace; slidevert makes it
-- drop in from the top like a Quake console.
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "myBezier", style = "slidevert" })
-- Slowly spins the active border's blue->green gradient. Keeps the compositor
-- redrawing the focused border continuously, so it costs some battery.
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "linear", style = "loop" })

-- Gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Layer rules: window blur doesn't reach layer-shell surfaces, so the bar,
-- launcher, notifications and OSD each need their own. Namespaces confirmed
-- via `hyprctl layers` with each one open. ignore_alpha skips fully
-- transparent pixels (bar margins, rounded corners) so only the visible
-- panel gets blurred.
for _, ns in ipairs({
  "waybar",
  "wofi",
  "notifications",
  "swayosd",
  "hyprshell_overview",
  "hyprshell_launcher",
  "hyprshell_switch",
}) do
  hl.layer_rule({
    name = "blur-" .. ns,
    match = { namespace = "^(" .. ns .. ")$" },
    blur = true,
    ignore_alpha = 0.1,
  })
end

-- dunst sits top-right, so its notifications slide in from the right edge;
-- the launcher pops in from the center.
hl.layer_rule({ name = "anim-notifications", match = { namespace = "^(notifications)$" }, animation = "slide right" })
hl.layer_rule({ name = "anim-wofi", match = { namespace = "^(wofi)$" }, animation = "popin 90%" })

-- Window Rules
hl.window_rule({
  name = "ghostty-rice",
  -- Ghostty's real Wayland app-id is "com.mitchellh.ghostty", not "ghostty"
  -- (confirmed via `hyprctl activewindow`) — the bare-word regex never matched.
  match = { class = "^(com.mitchellh.ghostty)$" },
  opacity = "0.95 0.85",
})

-- Brave showed the desktop wallpaper straight through its entire window,
-- with zero blending — not just the "0.9 active/0.8 inactive" rice from the
-- decoration block above. Root cause: Hyprland's per-window `opacity` value
-- is a MULTIPLIER on top of decoration:active_opacity/inactive_opacity, not
-- an absolute value, unless the `override` keyword follows each number.
-- "1.0 1.0" alone is therefore a no-op (1.0 * 0.9/0.8 == the same 0.9/0.8
-- rice everyone else gets) — confirmed by applying it live via `hyprctl
-- eval` against an already-open window with zero visible change. "1.0
-- override 1.0 override" actually pins it to fully opaque regardless of the
-- global rice values.
hl.window_rule({
  name = "brave-opaque",
  match = { class = "^(brave-browser)$" },
  opacity = "1.0 override 1.0 override",
})

-- Dropdown scratchpad terminal (SUPER + S), spawned/toggled by toggle-scratchpad.
-- Class must be a valid GTK app-id (dotted); a bare word like "scratchpad" is
-- silently rejected by ghostty ("invalid 'class' in config, ignoring").
hl.window_rule({
  name = "scratchpad-term",
  match = { class = "^(com.td.scratchpad)$" },
  float = true,
  size = "1400 900",
  workspace = "special:scratchpad",
})

-- Pop-up utilities (mostly waybar click targets) float centered instead of
-- squashing the tiled layout. Classes confirmed via `hyprctl clients`;
-- pavucontrol's is its reverse-DNS app-id.
for _, app in ipairs({
  { class = "org.pulseaudio.pavucontrol", size = "900 600" },
  { class = "blueman-manager", size = "800 550" },
  { class = "nm-connection-editor", size = "800 550" },
  { class = "imv", size = "1200 800" },
}) do
  hl.window_rule({
    name = "float-" .. app.class,
    match = { class = "^(" .. app.class .. ")$" },
    float = true,
    size = app.size,
    center = true,
  })
end

-- Bindings
local mainMod = "SUPER"

hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("cycle-wallpaper"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("toggle-blackout"))
-- Routed through waybar-hyprsunset (not hyprsunset directly) so the waybar
-- widget's override-tracking state file stays in sync with these too.
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("waybar-hyprsunset night 2500"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("waybar-hyprsunset day"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mainMod .. " + X", hl.dsp.window.kill())
-- Area screenshot opens swappy for annotation; swappy's own toolbar does the
-- copy/save (early_exit in its config closes it right after). Fullscreen
-- (Print) stays a plain instant copysave — no annotate step.
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("sh -c 'grimblast save area - | swappy -f -'"))
hl.bind("Print", hl.dsp.exec_cmd("grimblast --notify copysave output"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd("toggle-recording"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("sh -c 'umask 077; cliphist list | wofi --dmenu | cliphist decode | wl-copy'"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("toggle-scratchpad"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("dunstctl history-pop"))
-- Types the picked emoji into the focused window and copies it.
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("wofi-emoji"))

-- Window State
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(0))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.window.float())

-- Navigation
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))

-- Tabbed groups: G turns the focused window into a group (or dissolves it);
-- new windows opened while a group is focused join it. CTRL+Tab cycles tabs
-- (plain SUPER+Tab is hyprshell's overview).
-- CTRL+direction moves a window into the neighbouring group, or out of its
-- own group when there's none that way.
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + CTRL + Tab", hl.dsp.group.next())
hl.bind(mainMod .. " + CTRL + SHIFT + Tab", hl.dsp.group.prev())
hl.bind(mainMod .. " + CTRL + h", hl.dsp.window.move({ direction = "left", group_aware = true }))
hl.bind(mainMod .. " + CTRL + l", hl.dsp.window.move({ direction = "right", group_aware = true }))
hl.bind(mainMod .. " + CTRL + k", hl.dsp.window.move({ direction = "up", group_aware = true }))
hl.bind(mainMod .. " + CTRL + j", hl.dsp.window.move({ direction = "down", group_aware = true }))

-- SUPER+Tab (overview) and ALT+Tab (most-recently-used switcher) aren't
-- bound here: the hyprshell daemon (autostarted below) registers them at
-- runtime from users/td/hyprshell/config.json. scripts/check-keybinds.sh
-- reads that file too, so the README cheat sheet stays checked.

-- Workspaces
for i = 1, 9 do
  hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Mouse Bindings
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media Keys (swayosd-client shows the OSD and performs the adjustment)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume +5"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume -5"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness +5"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness -5"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })
-- Playback keys (Framework F4-F6, headset buttons) go to whichever MPRIS
-- player playerctl picks (the most recently active one). Locked so they
-- work from the lock screen too.
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Autostart
hl.on("hyprland.start", function()
  hl.exec_cmd("spice-vdagent")
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("hyprpolkitagent")
  hl.exec_cmd("hypridle")
  -- Clipboard history, with password-manager entries filtered out.
  -- cliphist stores plaintext in $XDG_CACHE_HOME/cliphist/db, where
  -- KeePassXC's own clear-clipboard timeout can't reach it. KeePassXC
  -- advertises the extra MIME type x-kde-passwordManagerHint on those
  -- selections. wl-paste --watch already turns that into
  -- CLIPBOARD_STATE=sensitive, which `cliphist store` skips; the text
  -- watcher's grep guard repeats the check so it doesn't depend on both
  -- tools keeping that behaviour. wl-clip-persist skips the same offers via
  -- its own documented regex recipe; `regular` (not `both`) is also its
  -- recommendation, since operating on the primary selection breaks text
  -- selection in GTK apps. See docs/gotchas.md.
  -- `umask 077` on every cliphist caller (these two and the SUPER+V bind):
  -- cliphist creates the db 0644, and whichever runs first after it's
  -- deleted is the one that creates it.
  hl.exec_cmd(
    "umask 077; wl-paste --type text --watch sh -c 'wl-paste --list-types | grep -q x-kde-passwordManagerHint || cliphist store'"
  )
  hl.exec_cmd("umask 077; wl-paste --type image --watch cliphist store")
  hl.exec_cmd("wl-clip-persist --clipboard regular --all-mime-type-regex '^(?!x-kde-passwordManagerHint).+'")
  hl.exec_cmd("swayosd-server")
  -- SUPER+Tab overview / ALT+Tab switcher. Autostarted rather than via Home
  -- Manager's services.hyprshell, whose unit waits on
  -- graphical-session.target, which this session never reaches.
  hl.exec_cmd("hyprshell run")
  -- syncthingtray is launched here, like swayosd-server, because nothing
  -- else would: it has no unit at all (only a .desktop file). --wait holds
  -- it until waybar's tray exists.
  hl.exec_cmd("syncthingtray --wait")
  hl.exec_cmd("waybar")
  hl.exec_cmd("awww-daemon")
  -- Bare invocation starts the daemon and loads the auto day/night schedule
  -- from hyprsunset.conf (see home.nix); SUPER+R/SHIFT+R below become
  -- manual IPC overrides against this same running daemon.
  hl.exec_cmd("hyprsunset")
  hl.exec_cmd("setup-wallpapers")
  hl.exec_cmd("cycle-wallpaper")
end)
