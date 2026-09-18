# Desktop reference (Hyprland / Tokyo Night)

Source files: `users/td/hypr/hyprland.lua` (binds, autostart, window rules,
per-host monitor config) and `users/td/home.nix` (all custom shell-script
packages, waybar/dunst/hyprlock/kanshi config, theming). One `hyprland.lua`
is shared byte-for-byte across all three hosts — `@HOSTNAME@` is
string-substituted at build time by `home.nix`, so host-specific behavior
inside it is `if "@HOSTNAME@" == "..."` branches, not separate files.

For the full keybinding table and feature-tour prose, `README.md` already
has an accurate, up-to-date cheat sheet — this file adds the *implementation*
detail an agent needs to change or debug something, not a duplicate table.

## Custom scripts (all defined in `users/td/home.nix` via `writeShellScriptBin`)

| Script | Bound to | What it does |
|---|---|---|
| `setup-wallpapers` | autostart | Downloads a starter wallpaper into `~/Pictures/Wallpapers` on first run (idempotent — skips if already present). |
| `cycle-wallpaper` | `SUPER+W`, autostart | Picks a random image from `~/Pictures/Wallpapers` via `awww img`. |
| `toggle-blackout` | `SUPER+SHIFT+W` | Solid-black background toggle for glare relief; uses `awww clear`/`awww restore`, state tracked by a `/tmp` sentinel file (no wallpaper path bookkeeping needed). |
| `toggle-scratchpad` | `SUPER+S` | Dropdown terminal. First call spawns a ghostty tagged `--class=com.td.scratchpad` into the `special:scratchpad` workspace (matched by the `scratchpad-term` window rule in `hyprland.lua`); later calls just toggle visibility. |
| `waybar-weather` | waybar module | wttr.in one-liner as JSON for waybar's `custom` module type; falls back to `"N/A"` on any fetch failure. |
| `waybar-power-profile` | waybar module (click = cycle) | Reads/cycles `power-profiles-daemon`'s profile. Only meaningful on `framework` (see `docs/hosts.md`) — reports "unavailable" elsewhere. |
| `waybar-hyprsunset` | waybar module (click = toggle), `SUPER+R`/`SUPER+SHIFT+R` | Blue-light filter widget. See gotcha below — this is the *only* correct way to drive hyprsunset once the daemon is already running. |
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

- `ghostty-rice` — opacity `0.95 0.85` on ghostty windows. Matches by
  `com.mitchellh.ghostty` (ghostty's real Wayland app-id, not `ghostty`).
- `brave-opaque` — forces Brave fully opaque via `override`. See
  `docs/gotchas.md` for why plain `"1.0 1.0"` doesn't work here.
- `scratchpad-term` — floats/sizes/pins the scratchpad terminal to
  `special:scratchpad`.

## Theming

Tokyo Night palette: Blue `#7aa2f7` (identity/active), Green `#9ece6a`
(location/success), Orange `#ff9e64` (status/warning), Red `#f7768e`
(critical). Applied consistently across `waybar/style.css`,
`wofi/style.css`, `wlogout/style.css`, `swayosd/style.css`, and the
`programs.hyprlock`/`services.dunst` settings blocks in `home.nix` — when
adding a new UI surface, reuse these exact hex values rather than picking new
ones.

GTK/Qt/dconf theming (`gtk`, `qt`, `dconf.settings` in `home.nix`) is the
declarative source of truth for dark mode + accent color — don't add
`gsettings` calls to Hyprland autostart to set these; they'd just fight the
declarative config on every rebuild.

## Kanshi (monitor layout)

`services.kanshi.settings` in `home.nix` has a `"docked"` profile with a
literal `CHANGE_ME` placeholder for the external display's identifier —
it intentionally never matches until someone replaces it with the real
output name from `hyprctl monitors` once a monitor is actually plugged in.
Don't remove it thinking it's dead code.
