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
  hl.monitor({
    output = "",
    mode = "2256x1504@60",
    position = "auto",
    scale = 1.175, -- 2256x1504 panel; 1.175 is the exact divisor Hyprland wants (-> 1920x1280 logical)
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
    rounding = 6,
    active_opacity = 0.9,
    inactive_opacity = 0.8,
    blur = {
      enabled = true,
      size = 1,
      passes = 1,
    },
  },

  animations = {
    enabled = true,
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
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })

-- Gestures
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Window Rules
hl.window_rule({
  name = "ghostty-rice",
  -- Ghostty's real Wayland app-id is "com.mitchellh.ghostty", not "ghostty"
  -- (confirmed via `hyprctl activewindow`) — the bare-word regex never matched.
  match = { class = "^(com.mitchellh.ghostty)$" },
  opacity = "0.95 0.85",
})

-- Brave doesn't paint a fully opaque backing surface the way native GTK/Qt
-- apps do, so the global active/inactive_opacity + blur above let the
-- wallpaper show through it (but not other apps). Force it fully opaque.
hl.window_rule({
  name = "brave-opaque",
  match = { class = "^(brave-browser)$" },
  opacity = "1.0 1.0",
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
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("sh -c 'cliphist list | wofi --dmenu | cliphist decode | wl-copy'"))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("wlogout"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("toggle-scratchpad"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("dunstctl history-pop"))

-- Window State
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(0))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.window.float())

-- Navigation
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))

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

-- Autostart
hl.on("hyprland.start", function()
  hl.exec_cmd("spice-vdagent")
  hl.exec_cmd("nm-applet --indicator")
  hl.exec_cmd("hyprpolkitagent")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("wl-clip-persist --clipboard both")
  hl.exec_cmd("swayosd-server")
  hl.exec_cmd("waybar")
  hl.exec_cmd("awww-daemon")
  -- Bare invocation starts the daemon and loads the auto day/night schedule
  -- from hyprsunset.conf (see home.nix); SUPER+R/SHIFT+R below become
  -- manual IPC overrides against this same running daemon.
  hl.exec_cmd("hyprsunset")
  hl.exec_cmd("setup-wallpapers")
  hl.exec_cmd("cycle-wallpaper")
end)
