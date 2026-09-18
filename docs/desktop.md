# Desktop reference (Hyprland / Tokyo Night)

Source files: `users/td/hypr/hyprland.lua` (binds, autostart, window rules,
per-host monitor config), `users/td/home.nix` (all custom shell-script
packages, dunst/hyprlock/hypridle/kanshi config, theming), and
`users/td/waybar/` (bar config + stylesheet, linked in by `home.nix`). A
single `hyprland.lua` source file is shared, unmodified, across all three
hosts — `home.nix` substitutes `@HOSTNAME@` into it at build time, so
host-specific behavior lives in `if "@HOSTNAME@" == "..."` branches inside
that one file, not in separate per-host configs.

`README.md` carries the same cheat sheet for humans, and `checks.keybindings`
(via `scripts/check-keybinds.sh`) fails `nix flake check` if README and
`hyprland.lua` disagree — so those two cannot silently drift apart.

**This file's table is not machine-checked**, so update it by hand when
binds change. **`hyprland.lua` is the source of truth**: regenerate from
`grep 'hl.bind' users/td/hypr/hyprland.lua` if any doc disagrees.

## Keybindings (authoritative — from `hyprland.lua`)

`mainMod` = `SUPER`.

| Bind | Action |
|---|---|
| `SUPER+T` / `SUPER+Return` | Ghostty terminal (two binds, same command) |
| `SUPER+E` | Thunar |
| `SUPER+Space` | `wofi --show drun` |
| `SUPER+S` | Toggle dropdown scratchpad terminal |
| `SUPER+X` | Kill active window |
| `SUPER+F` | Fullscreen |
| `SUPER+P` | Pseudotile |
| `SUPER+SHIFT+Space` | Toggle floating |
| `SUPER+h/j/k/l` | Focus left/down/up/right |
| `SUPER+1..9` | Switch workspace |
| `SUPER+SHIFT+1..9` | Move window to workspace |
| `SUPER+SHIFT+E` | Exit Hyprland |
| `SUPER+SHIFT+L` | Lock (hyprlock) |
| `SUPER+SHIFT+P` | Power menu (wlogout) |
| `SUPER+W` | Cycle wallpaper |
| `SUPER+SHIFT+W` | Toggle blackout wallpaper |
| `SUPER+R` | Hyprsunset night override @ 2500K |
| `SUPER+SHIFT+R` | Hyprsunset day (identity) |
| `SUPER+SHIFT+S` | Region screenshot → `swappy` for annotation (swappy's own toolbar does the copy/save) |
| `Print` | Full-output screenshot, instant copy+save, with notification |
| `SUPER+C` | `hyprpicker -a` color picker |
| `SUPER+V` | Clipboard history (`cliphist` → wofi) |
| `SUPER+N` | Pop last notification (`dunstctl history-pop`) |
| `SUPER+ALT+R` | Toggle screen recording |
| `SUPER+LMB` / `SUPER+RMB` | Drag to move / resize |
| Volume/brightness/mute keys | `swayosd-client` (shows OSD + applies change; `locked` so they work on the lock screen) |

## Waybar click actions

From `waybar/config.jsonc`, which is the source of truth:

| Module | Click |
|---|---|
| `cpu`, `memory` | `ghostty -e btm` |
| `bluetooth` | `blueman-manager` |
| `network` | `nm-connection-editor` |
| `pulseaudio` | `pavucontrol` |
| `custom/power-profile` | Cycle power profile |
| `custom/hyprsunset` | Toggle blue-light filter |
| `custom/power` | `wlogout` |
| `idle_inhibitor` | Toggle idle inhibit (built-in) |
| `hyprland/workspaces` | Activate workspace (scroll disabled) |

## Custom scripts (all defined in `users/td/home.nix` via `writeShellScriptBin`)

| Script | Bound to | What it does |
|---|---|---|
| `setup-wallpapers` | autostart | Downloads a starter wallpaper into `~/Pictures/Wallpapers` on first run (idempotent — skips if already present). |
| `cycle-wallpaper` | `SUPER+W`, autostart | Picks a random image from `~/Pictures/Wallpapers` via `awww img`. |
| `toggle-blackout` | `SUPER+SHIFT+W` | Solid-black background toggle for glare relief; uses `awww clear`/`awww restore`, state tracked by a `/tmp` sentinel file (no wallpaper path bookkeeping needed). |
| `toggle-scratchpad` | `SUPER+S` | Dropdown terminal. First call spawns a ghostty tagged `--class=com.td.scratchpad` into the `special:scratchpad` workspace (matched by the `scratchpad-term` window rule in `hyprland.lua`); later calls just toggle visibility. |
| `waybar-weather` | waybar module | wttr.in one-liner as JSON for waybar's `custom` module type; falls back to `"N/A"` on any fetch failure. |
| `waybar-power-profile` | waybar module (click = cycle) | Reads/cycles `power-profiles-daemon`'s profile. Only meaningful on `framework` (see `docs/hosts.md`) — reports "unavailable" elsewhere. |
| `waybar-hyprsunset` | waybar module (click = toggle), `SUPER+R`/`SUPER+SHIFT+R` | Blue-light filter widget. Per `docs/gotchas.md`, this is the *only* correct way to drive hyprsunset once the daemon is already running. |
| `toggle-recording` | `SUPER+ALT+R` | Starts/stops `wf-recorder` in the background, PID tracked in `/tmp`, saves timestamped mp4 to `~/Videos/Recordings`, dunst toast on start/stop. |

## hyprsunset day/night schedule

Single source of truth: the three `let`-bound constants at the top of
`home.nix` (`hyprsunsetDayStart`, `hyprsunsetNightStart`,
`hyprsunsetNightTemp`). They feed both the generated
`xdg.configFile."hypr/hyprsunset.conf"` (the daemon's own schedule) and the
`waybar-hyprsunset` script's schedule math — change them in one place, both
stay in sync. See `docs/gotchas.md` for why the widget can't just query the
daemon directly.

## Window rules (`hyprland.lua`)

- `ghostty-rice` — opacity `0.95 0.85` on ghostty windows (a multiplier on the
  global `0.9`/`0.8`, not an absolute value — see `docs/gotchas.md`). Matches
  by `com.mitchellh.ghostty` (ghostty's real Wayland app-id, not `ghostty`).
- `brave-opaque` — forces Brave fully opaque via `override`. See
  `docs/gotchas.md` for why plain `"1.0 1.0"` doesn't work here.
- `scratchpad-term` — floats the scratchpad terminal, sizes it `1400 900`,
  and puts it on `special:scratchpad`.

## Theming

Tokyo Night palette, as actually used across `waybar/style.css`,
`wofi/style.css`, `wlogout/style.css`, `swayosd/style.css`, and the
`programs.hyprlock` / `services.dunst` settings blocks in `home.nix`:

| Hex | Role |
|---|---|
| `#c0caf5` | Default foreground/text — the most-used token, on every surface |
| `#1a1b26` | Module/panel background (usually at `0.9` alpha) |
| `rgba(10, 11, 16, 0.85)` | Waybar's bar background and wlogout's backdrop (deeper than `#1a1b26`; same RGB as Ghostty's `background`) |
| `#7aa2f7` | Blue — identity, borders, active/accent (every stylesheet) |
| `#9ece6a` | Green — location, success/low urgency |
| `#ff9e64` | Orange — status, clock, warning, git branch |
| `#f7768e` | Red — critical/fail |
| `#7dcfff` | Cyan — per-module accent: bluetooth, hyprsunset day state |
| `#bb9af7` | Purple — per-module accent: memory |

Reuse these exact values when adding a UI surface rather than introducing new
ones. Of the stylesheets above, the last two appear only in waybar's, as
per-module accents, and aren't part of the core four. Ghostty's ANSI palette
(`ghostty/config`) also uses the cyan.

GTK/Qt/dconf theming (`gtk`, `qt`, `dconf.settings` in `home.nix`) is the
declarative source of truth for dark mode + accent color — don't add
`gsettings` calls to Hyprland autostart to set these; they'd just fight the
declarative config on every rebuild.

## Kanshi (monitor layout)

`services.kanshi.settings` in `home.nix` has a `"docked"` profile with a
literal `CHANGE_ME` placeholder for the external display's identifier —
it intentionally never matches until someone replaces it with the real
output name from `hyprctl monitors` once a monitor is actually plugged in.

**kanshi is launched from `hyprland.lua`'s autostart, not by its service.**
Home Manager's `kanshi.service` is `WantedBy`/`PartOf`
`graphical-session.target`, which this session never reaches (that's a UWSM
thing; this config launches Hyprland directly), so the unit stays inactive
and `services.kanshi` only generates `~/.config/kanshi/config`. The
`"laptop"` profile sets no mode or scale, so it leaves framework's
`hyprland.lua` monitor settings alone.

The same target problem affects every graphical user service here:

- **`hypridle`, `awww`:** their HM units are also wanted by
  `graphical-session.target` and stay inactive. `hyprland.lua` starts both
  directly (`hypridle`, `awww-daemon`).
- **`dunst`:** its unit is `Type=dbus`, so D-Bus activates it on the first
  notification. It works without the target.
- **`swayosd-server`, `syncthingtray`:** no unit at all (no HM service is
  enabled for either, and syncthingtray only ships a `.desktop` file, which
  nothing here processes). Autostart is the only thing that launches them.

Check with `pgrep -a <name>`, not `systemctl --user`, which reports the
unused units as inactive even while the processes run.
