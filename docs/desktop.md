# Desktop reference (Hyprland / Tokyo Night)

Source files: `users/td/hypr/hyprland.lua` (binds, autostart, window rules,
per-host monitor config), `users/td/home.nix` (all custom shell-script
packages, dunst/hyprlock/hypridle config, theming), and
`users/td/waybar/` (per-output bar layout in `config.jsonc`, shared module
definitions in `modules.jsonc`, stylesheet; all linked in by `home.nix`). A
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
| `SUPER+Tab` | hyprshell overview + launcher (all workspaces). Bound at runtime by the hyprshell daemon from `hyprshell/config.json`, not in `hyprland.lua` |
| `ALT+Tab` / `ALT+SHIFT+Tab` / `ALT+grave` | hyprshell switcher: most-recently-used windows on the current workspace; release Alt to switch. Also bound by the daemon |
| `SUPER+G` | Toggle tabbed group on the focused window |
| `SUPER+CTRL+Tab` / `SUPER+CTRL+SHIFT+Tab` | Next / previous tab in group |
| `SUPER+CTRL+h/j/k/l` | Move window into the neighbouring group, or out of its own (`group_aware` move) |
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
| `SUPER+period` | `wofi-emoji`: types the pick into the focused window (`wtype`) and copies it |
| `SUPER+N` | Pop last notification (`dunstctl history-pop`) |
| `SUPER+ALT+R` | Toggle screen recording |
| `SUPER+LMB` / `SUPER+RMB` | Drag to move / resize |
| Volume/brightness/mute keys | `swayosd-client` (shows OSD + applies change; `locked` so they work on the lock screen) |

## Waybar bars (one per output)

`waybar/config.jsonc` is an array of bars, each with its own `output` and
module lists. All of them `include` `waybar/modules.jsonc`, where every
module is defined once. Read `config.jsonc` for which bar shows what. How
outputs are matched:

- **Laptop panel:** by connector name, `eDP-1`. Its description can't be
  used because the panel reports no serial, so waybar sees it as
  `"BOE 0x0BCA "` with a trailing space.
- **Dells:** by description (`make model serial`), like the `desc:` monitor
  rules in `hyprland.lua`, because `DP-N` names follow the dock port.
- **The last bar:** excludes the named outputs and ends with `"*"`, so it
  covers the landscape Dell, dl-prototype, utm-vm and any unknown display.
  In waybar's `output` arrays, entries are checked in order, and a list of
  nothing but `!` exclusions matches nothing.

## Waybar click actions

From `waybar/modules.jsonc`, which is the source of truth:

| Module | Click |
|---|---|
| `cpu`, `memory` | `ghostty -e btm` |
| `bluetooth` | `blueman-manager` |
| `network` | `nm-connection-editor` |
| `pulseaudio` | `pavucontrol` |
| `custom/power-profile` | Cycle power profile |
| `custom/hyprsunset` | Toggle blue-light filter |
| `custom/power` | `wlogout` |
| `custom/dnd` | Pause/resume dunst (do not disturb) |
| `custom/cava` | Turn the audio visualizer off/on |
| `mpris` | Built-in defaults: play/pause, middle = previous, right = next |
| `idle_inhibitor` | Toggle idle inhibit (built-in) |
| `hyprland/workspaces` | Activate workspace (scroll disabled) |

## Custom scripts (all defined in `users/td/home.nix` via `writeShellScriptBin`)

| Script | Bound to | What it does |
|---|---|---|
| `setup-wallpapers` | autostart | Downloads a starter wallpaper into `~/Pictures/Wallpapers` on first run (idempotent — skips if already present). |
| `cycle-wallpaper` | `SUPER+W`, autostart | Picks a random image from `~/Pictures/Wallpapers` via `awww img`, with a `grow` transition at 120fps centered on the cursor. awww has no cursor alias, so the script converts `hyprctl cursorpos` into a fraction of the monitor under it; falls back to `center`. |
| `toggle-blackout` | `SUPER+SHIFT+W` | Solid-black background toggle for glare relief; uses `awww clear`/`awww restore`, state tracked by a `/tmp` sentinel file (no wallpaper path bookkeeping needed). |
| `toggle-scratchpad` | `SUPER+S` | Dropdown terminal. First call spawns a ghostty tagged `--class=com.td.scratchpad` into the `special:scratchpad` workspace (matched by the `scratchpad-term` window rule in `hyprland.lua`); later calls just toggle visibility. |
| `waybar-weather` | waybar module | wttr.in one-liner as JSON for waybar's `custom` module type; falls back to `"N/A"` on any fetch failure. |
| `waybar-power-profile` | waybar module (click = cycle) | Reads/cycles `power-profiles-daemon`'s profile. Only meaningful on `framework` (see `docs/hosts.md`) — reports "unavailable" elsewhere. |
| `waybar-hyprsunset` | waybar module (click = toggle), `SUPER+R`/`SUPER+SHIFT+R` | Blue-light filter widget. Per `docs/gotchas.md`, this is the *only* correct way to drive hyprsunset once the daemon is already running. |
| `waybar-dnd` | waybar module (click = toggle) | Do not disturb: `dunstctl set-paused toggle`. While paused dunst queues notifications rather than dropping them, and the module shows the queued count. |
| `waybar-cava` | waybar module (click = toggle) | Audio visualizer: runs the `cava` CLI in raw mode and maps each frame to block characters. Quiet frames show flat bars; it hides after `waybarCavaHideAfter` (10) seconds of them, so dialogue gaps don't make it flicker. It sits at the left end of `modules-right` rather than in the center group, so appearing and disappearing doesn't shift the clock. Off means cava isn't running and a dim note icon remains. Used instead of waybar's built-in `cava` module, whose only click action freezes the bars. Toggling signals the runners listed in `$XDG_RUNTIME_DIR/waybar-cava/`. |
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
- `float-<class>` — floats, sizes and centers pavucontrol
  (`org.pulseaudio.pavucontrol`), `blueman-manager`, `nm-connection-editor`
  and `imv`. Classes were read from `hyprctl clients`; check there before
  adding another app.

Layer rules: `blur-<namespace>` for `waybar`, `wofi`, `notifications`
(dunst), `swayosd` and hyprshell's three overlays (`hyprshell_overview`,
`hyprshell_launcher`, `hyprshell_switch`). Window blur doesn't apply to layer-shell surfaces.
`ignore_alpha = 0.1` keeps fully transparent margins and corners unblurred.
List namespaces with `hyprctl layers` while each surface is open.
`anim-notifications` slides dunst in from the right; `anim-wofi` pops the
launcher in.

Also in `hl.config`: `rounding = 12` to match the stylesheets' 12px panels,
`dim_special = 0.4` (default 0.2) to dim what's behind the scratchpad, and a
`group` block that colors tabbed groups' borders and tab bar from the
palette.

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
per-module accents, and aren't part of the core four.

The 16-color ANSI palette is defined twice with the same values: Ghostty's
(`ghostty/config`) and the TTY's `console.colors` (`modules/core/default.nix`).
It uses the colors above plus Tokyo Night yellow `#e0af68`, which none of
the stylesheets use. tuigreet's
`--theme` color names resolve through `console.colors`.

hyprshell's overview, launcher and switcher use `hyprshell/styles.css`,
which sets its CSS variables from the palette above.

Terminal tools themed in `home.nix`: `bat` and `zathura` use
tokyonight.nvim's own exports (from `pkgs.vimPlugins.tokyonight-nvim`);
`fzf` and `bottom` are set by hand from the palette above; `eza` reads
`LS_COLORS` from `vivid generate tokyonight-night`, generated at build time.
zsh's `syntaxHighlighting.styles` and `autosuggestion.highlight` are set by
hand from the palette. Neovim's tokyonight is set to `night` (LazyVim's own
default is `moon`) with a transparent background, in
`nvim/lua/plugins/colorscheme.lua`.

The lock screen's weather, battery and now-playing labels come from
`waybar-weather` and two small helpers in `home.nix` (`hyprlock-battery`,
`hyprlock-nowplaying`); each prints nothing when there's nothing to show.
hypridle dims the backlight to 10% at 270s idle (`brightnessctl -s`) and
restores it on input (`-r`), 30s before the 300s lock.

GTK/Qt/dconf theming (`gtk`, `qt`, `dconf.settings` in `home.nix`) is the
declarative source of truth for dark mode + accent color — don't add
`gsettings` calls to Hyprland autostart to set these; they'd just fight the
declarative config on every rebuild.

## Monitor layout

`hl.monitor` rules at the top of `hyprland.lua` are the only thing that sets
monitor mode, scale, position and rotation. There is no kanshi. Rules
that match a specific output win over the `output = ""` catch-all, and
Hyprland re-applies them when a monitor is plugged in, so docking needs no
separate profile switcher. On framework, the docked Dells are matched by
serial (`desc:`); see the rules for the current layout.

## Autostart instead of systemd user units

Home Manager's graphical user services are `WantedBy`/`PartOf`
`graphical-session.target`, which this session never reaches (that's a UWSM
thing; this config launches Hyprland directly), so their units stay
inactive and `hyprland.lua`'s autostart launches the processes instead:

- **`hypridle`, `awww`:** their HM units are also wanted by
  `graphical-session.target` and stay inactive. `hyprland.lua` starts both
  directly (`hypridle`, `awww-daemon`).
- **`dunst`:** its unit is `Type=dbus`, so D-Bus activates it on the first
  notification. It works without the target.
- **`swayosd-server`, `syncthingtray`:** no unit at all (no HM service is
  enabled for either, and syncthingtray only ships a `.desktop` file, which
  nothing here processes). Autostart is the only thing that launches them.
- **`hyprshell`:** HM's `services.hyprshell` would work, but its unit is
  wanted by `wayland.systemd.target`, which defaults to
  `graphical-session.target`, so it isn't enabled; autostart runs
  `hyprshell run`, which finds `~/.config/hyprshell/config.json` itself.

Check with `pgrep -a <name>`, not `systemctl --user`, which reports the
unused units as inactive even while the processes run.
