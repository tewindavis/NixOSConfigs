# Desktop reference (Hyprland / Tokyo Night)

Source files: `users/td/hypr/hyprland.lua` (binds, autostart, window rules,
per-host monitor config), `users/td/home.nix` (all custom shell-script
packages, swaync/hyprlock/hypridle config, theming), and
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
`grep 'hl.bind' users/td/hypr/hyprland.lua` if any doc disagrees, plus
`users/td/hyprshell/config.json` for the two binds hyprshell registers.

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
| `SUPER+SHIFT+F` | `perf-mode toggle` (blur, shadows, animations off; video wallpapers paused, visualizer stopped) |
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
| `SUPER+SHIFT+S` | Region screenshot (`grimblast save area`) → `swappy` for annotation (swappy's own toolbar does the copy/save) |
| `Print` | Full-output screenshot (`grimblast --notify copysave output`), instant copy+save, with notification |
| `SUPER+SHIFT+T` | OCR the selected region to the clipboard (`ocr-region`) |
| `SUPER+C` | `hyprpicker -a` color picker |
| `SUPER+V` | Clipboard history (`cliphist` → wofi) |
| `SUPER+period` | `wofi-emoji`: types the pick into the focused window (`wtype`) and copies it |
| `SUPER+N` | Toggle the swaync notification center (`swaync-client -t -sw`) |
| `SUPER+ALT+R` | Toggle screen recording |
| `SUPER+LMB` / `SUPER+RMB` | Drag to move / resize |
| Volume/brightness/mute keys | `swayosd-client` (shows OSD + applies change; `locked` so they work on the lock screen) |
| Play/Pause, Next, Previous keys | `playerctl play-pause` / `next` / `previous` on the most recently active player; also `locked` |

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
| `custom/perf` | Toggle performance mode (`perf-mode toggle`); dim wand icon means the effects are currently off |
| `custom/power` | `wlogout` |
| `custom/notification` | Click: toggle the swaync notification center. Right-click: toggle do not disturb (`swaync-client -d`). State comes from `swaync-client -swb`; its `alt` value picks the icon and is the CSS class |
| `custom/cava` | Turn the audio visualizer off/on |
| `mpris` | Built-in defaults: play/pause, middle = previous, right = next |
| `idle_inhibitor` | Toggle idle inhibit (built-in) |
| `hyprland/workspaces` | Activate workspace (scroll disabled). Per-monitor (`all-outputs: false`), no persistent workspaces, and `workspace-taskbar` draws app icons (Papirus-Dark) after each number |

## Custom scripts (all defined in `users/td/home.nix` via `writeShellScriptBin`)

| Script | Bound to | What it does |
|---|---|---|
| `setup-wallpapers` | autostart | Downloads a starter wallpaper into `~/Pictures/Wallpapers` on first run (idempotent — skips if already present). |
| `cycle-wallpaper` | `SUPER+W`, autostart | Gives each monitor its own random pick from `~/Pictures/Wallpapers` (picks repeat only when there are fewer files than monitors). Stills (`.jpg`/`.png`/`.webp`) go through `awww img -o <output>` with a `grow` transition at 120fps, growing from the cursor on the monitor under it (awww has no cursor alias, so `hyprctl cursorpos` is converted into a fraction of that monitor) and from `center` elsewhere; that output's video, if any, is stopped first. Videos (`.mp4`/`.webm`/`.mkv`/`.mov`) go to `wallpaper-video start`. |
| `toggle-blackout` | `SUPER+SHIFT+W` | Solid-black background toggle for glare relief: `wallpaper-video stop-all keep` (videos sit above awww, so they must go) then `awww clear`; off again runs `awww restore` and `wallpaper-video resume-saved`. State is a sentinel file in `$XDG_RUNTIME_DIR`. |
| `toggle-scratchpad` | `SUPER+S` | Dropdown terminal. First call spawns a ghostty tagged `--class=com.td.scratchpad` into the `special:scratchpad` workspace (matched by the `scratchpad-term` window rule in `hyprland.lua`); later calls just toggle visibility. |
| `waybar-weather` | waybar module | wttr.in one-liner as JSON for waybar's `custom` module type; falls back to `"N/A"` on any fetch failure. |
| `waybar-power-profile` | waybar module (click = cycle) | Reads/cycles `power-profiles-daemon`'s profile. Only meaningful on `framework` (see `docs/hosts.md`) — reports "unavailable" elsewhere. |
| `waybar-hyprsunset` | waybar module (click = toggle), `SUPER+R`/`SUPER+SHIFT+R` | Blue-light filter widget. Per `docs/gotchas.md`, this is the *only* correct way to drive hyprsunset once the daemon is already running. |
| `waybar-cava` | waybar module (click = toggle) | Audio visualizer: runs the `cava` CLI in raw mode and maps each frame to block characters. Quiet frames show flat bars; it hides after `waybarCavaHideAfter` (10) seconds of them, so dialogue gaps don't make it flicker. It sits at the left end of `modules-right` rather than in the center group, so appearing and disappearing doesn't shift the clock. Off means cava isn't running and a dim note icon remains. Used instead of waybar's built-in `cava` module, whose only click action freezes the bars. Toggling signals the runners listed in `$XDG_RUNTIME_DIR/waybar-cava/`. `toggle`/`on`/`off`/`status`: the forced forms and the query exist for `perf-mode`, which has to set a state rather than flip one. |
| `update-check` | `update-check` user timer (daily 10:00, catches up after sleep) | Runs `nix flake update --output-lock-file <temp>` so `/etc/nixos` is never touched, compares it with `flake.lock`, and if any input is newer shows a notification listing them with **Update now** / **Later**. Waits for a network (`nm-online`); a failed check is silent until the next day. |
| `update-apply` | "Update now" (opens in Ghostty) | Refuses if `flake.lock` has uncommitted changes. Otherwise `nix flake update`, then `nh os switch /etc/nixos -H <this host's flake attr> --ask`, which shows the package diff and asks before activating. Declining restores `flake.lock`; accepting offers to commit it. |
| `idle-dim` | hypridle (270s idle / resume) | `idle-dim dim` saves the current backlight level in `$XDG_RUNTIME_DIR` and sets 10%; `idle-dim restore` puts it back. Replaces `brightnessctl -s`/`-r`, whose save file is a fixed `/tmp` path. |
| `grafana-tunnel` | by hand: `grafana-tunnel <host> [local-port]` | SSH tunnel to Grafana on a monitoring host (dl-prototype, utm-nixos), where it listens only on 127.0.0.1, then opens the browser at `http://localhost:<port>`. See `modules/services/monitoring.nix`. |
| `wallpaper-video` | `cycle-wallpaper`, `toggle-blackout`, `perf-mode`, `power-watch` | Video wallpapers: one `mpvpaper` per output (`-p -a FULL`: pauses itself under a fullscreen window; `panscan=1.0` crops to fill), each with an mpv IPC socket in `$XDG_RUNTIME_DIR/wallpaper-video/`. `start`, `stop`, `stop-all [keep]`, `resume-saved`, `sync` (pause/resume to match `should-play`: on AC and performance mode off). |
| `perf-mode` | `custom/perf` waybar button, `SUPER+SHIFT+F`; `power-watch` | `on`/`off`/`toggle`/`status`/`waybar` (the last renders the bar module). Sets `animations.enabled`, `decoration.blur.enabled` and `decoration.shadow.enabled` live via `hyprctl eval`, then `wallpaper-video sync` and `waybar-cava off`. Reads the live `animations:enabled` rather than a flag, since a config reload resets it. The visualizer is only turned back on if performance mode was what stopped it, tracked by a sentinel in `$XDG_RUNTIME_DIR` so a deliberate click on `custom/cava` survives a round trip. |
| `power-watch` | autostart | Loop, every 10s: entering the power-saver profile runs `perf-mode on`, leaving it `perf-mode off` (changes only, so a manual toggle holds until the next change); keeps video wallpapers paused whenever they shouldn't play, re-applied each tick because mpvpaper's auto-pause can resume one when a fullscreen window closes; and warns on battery — normal notification at 20%, critical at 10%, once each per discharge, rearmed when the charger goes back in. Hosts with no `/sys/class/power_supply/BAT*` skip the battery part. |
| `media-inhibit` | autostart | Holds a logind idle inhibitor (`systemd-inhibit --what=idle`) while PipeWire has an output stream in the `running` state, so hypridle's dim/lock/suspend all wait out a video or a long track. hypridle's `ignore_systemd_inhibit` defaults to false, so no hypridle config is needed. Pausing drops the stream out of `running`, re-arming the lock within a tick (30s); the notification blips are excluded by `application.name`, and capture streams (the visualizer) are a different `media.class`. An inhibitor outlives its watcher, so the script releases any left by a previous run at startup, and sleeps in the background so its TERM trap runs immediately rather than up to 30s later. |
| `ocr-region` | `SUPER+SHIFT+T` | `grimblast --freeze save area -` piped through `tesseract -l eng` into `wl-copy`; `--freeze` so a moving frame or an open menu can be selected. Notifies with the character count and a 120-char preview, or "No text found". The preview escapes Pango markup (OCR output is untrusted text, and swaync renders bodies as markup); the clipboard gets it verbatim. `umask 077` like the other clipboard callers. |
| `toggle-recording` | `SUPER+ALT+R` | Starts/stops `wf-recorder` in the background, PID tracked in `$XDG_RUNTIME_DIR` (checked to still be `wf-recorder` before it's signalled), saves timestamped mp4 to `~/Videos/Recordings`, `notify-send` toast on start/stop. |

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

Layer rules: `blur-<namespace>` for `waybar`, `wofi`,
`swaync-notification-window`, `swaync-control-center`, `swayosd` and hyprshell's three overlays (`hyprshell_overview`,
`hyprshell_launcher`, `hyprshell_switch`). Window blur doesn't apply to layer-shell surfaces.
`ignore_alpha = 0.1` keeps fully transparent margins and corners unblurred.
List namespaces with `hyprctl layers` while each surface is open.
`anim-notifications` slides swaync's popups and panel in from the right; `anim-wofi` pops the
launcher in.

Also in `hl.config`: `rounding = 12` to match the stylesheets' 12px panels,
`dim_special = 0.4` (default 0.2) to dim what's behind the scratchpad, and a
`group` block that colors tabbed groups' borders and tab bar from the
palette.

## Theming

Tokyo Night palette, as actually used across `waybar/style.css`,
`wofi/style.css`, `wlogout/style.css`, `swayosd/style.css`, and the
`programs.hyprlock` settings block in `home.nix` and `swaync/style.css`:

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
`fzf` and `bottom` are set by hand from the palette above; yazi uses
tokyonight's yazi export (with its `[filetype]` `name` keys rewritten to
`url` at build time, see `docs/gotchas.md`); `eza` reads
`LS_COLORS` from `vivid generate tokyonight-night`, generated at build time.
zsh's `syntaxHighlighting.styles` and `autosuggestion.highlight` are set by
hand from the palette. Neovim's tokyonight is set to `night` (LazyVim's own
default is `moon`) with a transparent background, in
`nvim/lua/plugins/colorscheme.lua`.

The lock screen's weather, battery and now-playing labels come from
`waybar-weather` and two small helpers in `home.nix` (`hyprlock-battery`,
`hyprlock-nowplaying`); each prints nothing when there's nothing to show.
hypridle dims the backlight to 10% at 270s idle and restores it on input,
30s before the 300s lock, via `idle-dim dim|restore` (saves the previous
level in `$XDG_RUNTIME_DIR` rather than brightnessctl's fixed `/tmp` path).

GTK apps' colors come from `gtk.gtk3.extraCss` / `gtk.gtk4.extraCss`
(`gtkNamedColors`, plus `gtkCssVariables` for newer libadwaita): the
named colors adw-gtk3 and libadwaita read, set from the palette, with
header bars and sidebars in `#15161e` around `#1a1b26` content.

Brave's tab strip and toolbar are tinted by a managed Chromium policy,
`BrowserThemeColor = "#1a1b26"`, written to
`/etc/brave/policies/managed/theme.json` by `modules/desktop/default.nix`.
Brave can't make only its frame transparent, so this blends it instead.
Chromium derives the rest of the toolbar palette from that seed color.
Side effects: Brave reports itself as managed, and its theme color can't
be changed from settings. Check it's applied at `brave://policy`; policies
are read only when Brave starts.

Notifications are swaync (`services.swaync`, config and style in
`swaync/`, plus `scripts` added in `home.nix`). Sounds come from those
scripts via `notify-sound`: `message-new-email` for normal urgency
(skipped while do-not-disturb is on), `dialog-warning-auth` for critical
(always, as critical popups bypass DND), nothing for low; KDE's ocean sound
theme, played with `pw-play --volume` at `notifySoundVolume` (0.10, a stream
gain on top of the sink volume). Ocean rather than freedesktop because its
tones sit near 350-500Hz; freedesktop's `message-new-instant` centres near
900Hz with a 466Hz peak, which distorted the Framework's speakers. `style.css` only overrides the palette variables, font and
urgency borders of swaync's packaged stylesheet, which swaync always loads
first.

Qt apps use `qt5ct`/`qt6ct` (`qt.platformTheme.name = "qtct"`) with the
Fusion style and `qtColorScheme` in `home.nix`, a palette built from the
table above. Home Manager exports `QT_QPA_PLATFORMTHEME=qt5ct` for both Qt
versions; the qt5ct plugin registers both `qt5ct` and `qt6ct`, so Qt 6 apps
load it too (qt6ct's own settings window warns about the name; harmless).
KeePassXC is exempt: `home.nix` wraps it to unset `QT_QPA_PLATFORMTHEME`
and `QT_STYLE_OVERRIDE`, so qt5ct never loads into the password manager
(see `docs/security.md`), and it uses its own Dark theme
(`[GUI] ApplicationTheme=dark` in `~/.config/keepassxc/keepassxc.ini`, set
by hand because KeePassXC writes that file itself).

`git` goes through `delta` (`programs.delta`, `programs.git`): side-by-side,
line numbers, `syntax-theme = tokyonight_night` (bat's theme cache) and
tokyonight's delta diff colors via a git `include`. Identity still lives in
the hand-written `~/.gitconfig`, which git reads after
`~/.config/git/config`.

Neovim's start screen header (`nvim/lua/plugins/dashboard.lua`) is
block-letter NIXOS, one snacks text section per row so each row gets its
own highlight along the #7aa2f7 -> #9ece6a gradient.

The cursor is catppuccin mocha blue (`gtk.cursorTheme`). Its package also
ships a hyprcursor (vector) version, which Hyprland uses via
`HYPRCURSOR_THEME`/`HYPRCURSOR_SIZE` in `home.sessionVariables`, set from
`gtk.cursorTheme`; without them Hyprland scales the bitmap XCursor to
fractional scales, which blurs it. `hyprctl setcursor <theme> <size>`
switches it live.

Starship's `right_format` shows `cmd_duration` (commands over 2s) and the
time. Ghostty's `custom-shader` is `ghostty/shaders/cursor_trail.glsl`, a
fading trail when the cursor moves two or more cells; shaders keep an
animation loop running while a Ghostty window is focused.

Fonts (`modules/desktop/default.nix`): Nerd Font builds of JetBrains Mono
(the UI and terminal font throughout), Fira Code and Zed Mono, plus Noto
Color Emoji. Inter is the GTK UI font (`home.nix`).

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
- **`swaync`:** its HM unit (`services.swaync`) is `Type=dbus` with
  `BusName=org.freedesktop.Notifications`, so D-Bus activates it on the
  first notification or `swaync-client` call. It works without the target.
- **`swayosd-server`, `syncthingtray`:** no unit at all (no HM service is
  enabled for either, and syncthingtray only ships a `.desktop` file, which
  nothing here processes). Autostart is the only thing that launches them.
- **`hyprshell`:** HM's `services.hyprshell` would work, but its unit is
  wanted by `wayland.systemd.target`, which defaults to
  `graphical-session.target`, so it isn't enabled; autostart runs
  `hyprshell run`, which finds `~/.config/hyprshell/config.json` itself.

`power-watch` and `media-inhibit` (above) are autostarted the same way. The same autostart also runs helpers that were never units: `nm-applet
--indicator` (network icon in the waybar tray), `hyprpolkitagent` (the
password prompt for privileged GUI actions such as mounting drives in
Thunar; without an agent they fail silently), the clipboard watchers, and
`spice-vdagent` (only does anything in the VM). `hyprland.lua`'s
`hyprland.start` handler is the complete list.

Check with `pgrep -a <name>`, not `systemctl --user`, which reports the
unused units as inactive even while the processes run.
