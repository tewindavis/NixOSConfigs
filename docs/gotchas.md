# Gotchas and tribal knowledge

Non-obvious bugs and constraints already hit and fixed in this repo, mined
from code comments and commit history. Check here before re-debugging one of
these from scratch.

## Hyprland 0.56+ / hyprland.lua

- **Config format:** 0.56+ treats the old `.conf`/hyprlang syntax as
  *legacy* and looks for `hyprland.lua` first. This repo already migrated
  (2026-09-15) — don't add a `hyprland.conf`.
- **Dispatch args are Lua expressions, not strings.** Plain `hyprctl dispatch
  <dispatcher> <args>` no longer works on this version. Correct form,
  confirmed live: `hyprctl dispatch 'hl.dsp.window.float()'`, `hyprctl
  dispatch 'hl.dsp.dpms(false)'`, `hyprctl dispatch
  'hl.dsp.workspace.toggle_special("scratchpad")'`. All the custom scripts in
  `home.nix` (`toggle-scratchpad`, hypridle DPMS listeners, wlogout's Logout
  action) already use this form — copy their pattern for new dispatch calls
  rather than the classic `hyprctl dispatch <name> <arg>` syntax from older
  docs.
- **App-id vs class name:** Wayland apps' real app-id can differ from their
  package name — e.g. ghostty is `com.mitchellh.ghostty`, not `ghostty`.
  Confirm via `hyprctl activewindow` before writing a window rule's `match`,
  rather than guessing from the binary name.
- **Custom `--class` must be a dotted GTK app-id.** A bare word like
  `scratchpad` is silently rejected by ghostty ("invalid 'class' in config,
  ignoring"). Use a reverse-DNS-style id (`com.td.scratchpad`, as
  `toggle-scratchpad` does).
- **Per-window `opacity` is a *multiplier* on `decoration.active_opacity` /
  `inactive_opacity`, not an absolute value**, unless the `override` keyword
  follows each number. `"1.0 1.0"` is a no-op if the global rice is already
  `0.9`/`0.8` (`1.0 * 0.9 = 0.9`) — confirmed via `hyprctl eval` against a
  live window with zero visible change. To force a window fully opaque
  regardless of global settings, use `"1.0 override 1.0 override"` (see the
  `brave-opaque` window rule).
- **`hl.monitor({ output = "" })` matches every output, docked ones
  included.** framework's panel rule used to be that catch-all, so both 4K
  Dells came up at 2256x1504 with 1.175 scale. Scope panel rules to `eDP-1`
  and match externals by `desc:<make model serial>` from `hyprctl monitors`.
  `DP-N` names follow the dock port and swap if the cables do. Rules can be
  trialled live with `hyprctl eval 'hl.monitor({ ... })'` before editing.
  `transform = 1` vs `3` (90° vs 270°) is easiest to settle by trying one.
- **A Thunderbolt dock that enumerates but does nothing** (no displays, no USB):
  check `/sys/bus/thunderbolt/devices/*/authorized`. At security level `user`
  it stays `0` until bolt approves the dock, which is why framework enables
  `services.hardware.bolt`.

- **Swallowing can't be limited to particular apps.** `misc:swallow_regex`
  matches the *terminal's* class and `swallow_exception_regex` its title
  (`CWindow::getSwallowee` in `src/desktop/view/Window.cpp`); the new
  window's class is never checked, and there is no no-swallow window rule
  in 0.56. With `swallow_regex` set to Ghostty, every graphical app
  launched from Ghostty swallows it.
- **There is no workspace-overview plugin for 0.56.** hyprexpo was
  dropped from `hyprwm/hyprland-plugins` by its `v0.56.0` tag (the README's
  Nix example still names it), and nixpkgs' `hyprlandPlugins.hyprspace`
  fails to compile against 0.56 (`AnimationManager.hpp` moved). Plugins
  are built against Hyprland's internal headers, so check that one builds
  (`nix build .#nixosConfigurations.framework.pkgs.hyprlandPlugins.<name>`)
  before wiring it in.
- **Layer-shell surfaces need their own blur.** `decoration.blur` only
  covers windows; waybar, wofi, swaync and swayosd are blurred by the
  `hl.layer_rule` loop in `hyprland.lua`. Namespaces aren't the binary
  names (swaync's are `swaync-notification-window` and
  `swaync-control-center`); read them from `hyprctl layers` with
  the surface open. `hl.layer_rule`/`hl.animation` reject unknown fields,
  leaves, styles and bezier names with an error, so `hyprctl eval` is a
  cheap way to validate one before editing.

- **Group dispatchers:** `hl.dsp.group.move_window` only reorders tabs
  inside a group. Moving a window into or out of a group is
  `hl.dsp.window.move({ direction = ..., group_aware = true })` (also
  `into_group = "<dir>"` / `out_of_group = true`). Dispatcher builders
  don't validate their arguments, so a wrong field silently does the
  default; check `src/config/lua/bindings/LuaBindingsDispatchers.cpp`.

- **Starting hyprshell reloads Hyprland's config.** `hyprshell run`
  triggers a config reload at startup (its log says "Reloading hyprland
  config"; `reload_hyprland_config` in `crates/exec-lib`), which throws away
  anything applied live with `hyprctl eval` and reloads the *deployed*
  `~/.config/hypr/hyprland.lua`. Trialling a change live and then starting
  hyprshell reverts it; deploy first (`nh os switch`), or restart hyprshell
  before the live experiment rather than after.
- **hyprshell supports one switcher.** Its config accepts `switch_2`, but
  only the config crates read it; the daemon never binds it (4.10.8).
  `switch` (ALT+Tab) and `overview` (SUPER+Tab) are the two modes.
- **`pgrep -f`/`pkill -f` match your own shell.** Any command line that
  contains the pattern matches, including the shell running the pgrep.
  That killed test shells twice and hid a dead hyprshell daemon once while
  building these features. Use `pgrep -x <name>` or a PID file.

## Other apps

- **tokyonight's yazi theme needs patching for yazi 26.** Its `[filetype]`
  rules use `{ name = ... }`; yazi 26 wants `url` and rejects the *whole*
  theme ("at least one of `url` or `mime` must be specified"), falling back
  to its preset. `home.nix` rewrites the key with `sed` when linking it.
- **`mpvpaper` doesn't show up as `mpvpaper`.** The Nix wrapper's process is
  `.mpvpaper-wrapped`, truncated to `.mpvpaper-wrapp` in `comm`, so
  `pgrep -x mpvpaper` finds nothing even while videos play. Use
  `ps -eo comm= | grep mpvpaper`, or `wallpaper-video`'s own PID files.
- **swaync scripts run during do-not-disturb,** and a script that exits
  non-zero makes swaync post a "script failed" notification, which runs
  the scripts again. `notify-sound` checks DND itself for normal urgency
  and always exits 0 so a missing audio device can't loop.

- **delta ignores `git -c` config.** It reads git config from the files on
  disk (libgit2), so `git -c include.path=... diff` changes git but not
  delta's options. To test a delta config, put it where git will find it,
  e.g. `XDG_CONFIG_HOME=<dir>` with `<dir>/git/config`.
- **KeePassXC ignores the Qt palette by default.** Its "Automatic" theme
  draws its own light/dark style; only *Classic* follows the platform
  palette. That's a KeePassXC setting (`[GUI] ApplicationTheme`), not
  something `qt.*` can change. Here KeePassXC runs without qt5ct anyway
  (`docs/security.md`), so it's set to its own `dark`; *Classic* without a
  platform theme falls back to Fusion's light palette.
- **Testing Neovim with the repo as its config dir writes into the repo.**
  Pointing `XDG_CONFIG_HOME` at a directory linking to `users/td/nvim`
  lets LazyVim write `lazyvim.json` there. The deployed config is a
  read-only store path, so this only happens in tests; delete the stray
  file afterwards.

- **QGIS lists no GRASS algorithms until its provider is enabled.** The
  `grassprovider` plugin ships with QGIS but starts disabled (in the GUI:
  Plugins → Installed → GRASS GIS provider; headless:
  `qgis_process plugins enable grassprovider`, which writes to the QGIS
  profile). Once enabled it finds `grass` on `PATH` (307 algorithms,
  verified by running `grass:g.version` through `qgis_process`). The
  native GRASS plugin needs `qgis-ltr.override { withGrass = true; }`,
  which isn't cached and builds QGIS from source.

## Waybar

- **Match the laptop panel by connector name, not description.** waybar
  compares `output` against the xdg-output description, which is
  `make model serial`. The Framework panel has no serial, so it comes out
  `"BOE 0x0BCA "` with a trailing space, and `"BOE 0x0BCA"` silently fails
  to match (the bar just falls through to the catch-all). The Dells report
  serials, so their descriptions have no trailing space.
- **`workspace-taskbar` needs `{windows}` in the workspace `format`.**
  Waybar only reads the `workspace-taskbar` settings when the format
  string contains `{windows}` (`parseConfig` in
  `src/modules/hyprland/workspaces.cpp`); without it `enable: true` is
  silently ignored and no icons appear. The icons are drawn where
  `{windows}` sits.
- **The privacy module sees cava as a microphone user.** cava captures
  audio through a PipeWire stream with `node.name = cava` (both waybar's
  built-in module and the CLI that `waybar-cava` runs), so `privacy`
  ignores that name for `audio-in` (`modules.jsonc`).
- **Don't signal `waybar-cava` runners with `pkill -f`.** A pattern like
  `pkill -f "bin/waybar-cava run"` also matches any shell whose command
  line contains that text, and USR1's default action kills it. This
  happened twice while testing. Runners register their PIDs in
  `$XDG_RUNTIME_DIR/waybar-cava/` instead, and the toggle checks
  `/proc/<pid>/cmdline` before signaling. Test it with the real
  `XDG_RUNTIME_DIR`: cava finds PipeWire's socket there and exits at once
  without it.

## hyprsunset

- **No IPC query for current state.** There's no way to ask the daemon
  "what are you doing right now" — `waybar-hyprsunset` instead
  reconstructs the expected state by recomputing the schedule from the same
  constants `hyprsunset.conf` was generated from, and treats any manual
  override as stale once the next scheduled boundary crossing should have
  happened.
- **Re-running the `hyprsunset` binary does not control an already-running
  daemon** in v0.4.0 (e.g. `hyprsunset --identity`) — it tries to bind its
  own CTM manager, loses to the running daemon, and fails with "A CTM
  manager is already running" *without changing anything on screen*. Control
  the running daemon instead via its plaintext control socket:
  `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.hyprsunset.sock`
  (see `waybar-hyprsunset` for the `socat` invocation). Always go through
  `waybar-hyprsunset` (not `hyprsunset` directly) for any new manual-override
  entry point, so the widget's override-state file doesn't fall out of sync.

## NVIDIA (`modules/hardware/nvidia.nix`)

- `hardware.nvidia.powerManagement.enable` and `.finegrained` are both left
  `false` deliberately. Per the source comments, `powerManagement.enable` is
  experimental and "can cause sleep/suspend to fail"; `.finegrained` (turn the
  GPU off when idle) is experimental too and only works on Turing or newer.
  Don't flip either on without testing suspend/resume specifically.
- `open = false` — this selects NVIDIA's *proprietary* kernel module over
  NVIDIA's own **open-source kernel module**, which (as the source comment
  stresses) is **not** the `nouveau` driver — don't conflate the two. The
  open module only supports RTX 20-series/Turing and newer, so this stays
  `false` until it's confirmed appropriate for the actual GPU in
  `dl-prototype`.

## RL / binary-analysis Python env (`modules/dev/rl-binary.nix`)

- `pwndbg` is **not** a real nixpkgs package (it ships its own
  `setup.sh`/venv installer upstream) — `gef` is the nixpkgs-packaged
  equivalent used instead for the same GDB-enhancement use case. Don't add a
  `pwndbg` package reference expecting it to resolve.
- Both `gymnasium` and `stable-baselines3` are overridden with `doCheck =
  false`. Reason: their `nativeCheckInputs` transitively pull in `tensorflow`
  — gymnasium's via flax → keras → tf-keras, stable-baselines3's via
  tensorboard — and tensorflow is marked broken in this nixpkgs pin.
  `gymnasium` is patched *before* being passed into
  `stable-baselines3.override { gymnasium = ...; }` — patching it as a sibling
  package instead would not retroactively fix `stable-baselines3`'s own
  `propagatedBuildInputs` reference to the unpatched version.

## Neovim / LazyVim

- LSPs/formatters/linters are installed via Nix in `home.nix` (grouped by
  LazyVim language extra in comments there), **not** via Mason — Mason is
  explicitly disabled in `users/td/nvim/lua/plugins/mason.lua` so editor
  tooling stays reproducible via `nixos-rebuild` instead of drifting from
  whatever Mason downloaded at runtime. When adding language support, add
  the LSP/formatter package to `home.nix`, don't rely on `:Mason` to install
  it.
- **A LazyVim language extra can still reach around Nix.** Disabling Mason
  stops Mason from fetching things; it does not stop a *plugin* from doing
  its own download in a `build` step. `lazyvim.plugins.extras.lang.markdown`
  pulls in `iamcco/markdown-preview.nvim`, whose build step calls the GitHub
  releases API and downloads a ~45 MB prebuilt Node server into `app/bin/`
  with no checksum and no signature — and upstream has been dormant since
  2023 (last commit 2023-10-17, last release 2022-05-13), so that binary is a
  2022 runtime from an unmaintained repo. It is disabled in
  `users/td/nvim/lua/plugins/markdown-preview.lua`; `render-markdown.nvim`
  covers in-buffer rendering instead. When adding a LazyVim extra, check its
  specs for `build`/`run` keys rather than assuming Mason-disabled means
  nothing is fetched.
- **A `build` key isn't the only way a plugin fetches a binary.**
  `blink.cmp` (LazyVim's default completion) has no build step on a release
  tag. Instead, when it loads, it downloads a prebuilt native library
  (`target/release/libblink_cmp_fuzzy.so`, ~2 MB) from its GitHub release
  and loads it into nvim. It checks a sha256 that comes from the same
  release, which catches corruption but not a compromised release. Unlike
  markdown-preview, upstream is active, so it is left enabled. Setting
  `fuzzy.implementation = "lua"` in its opts would avoid the download, at
  the cost of slower fuzzy matching.
- `programs.neovim.sideloadInitLua = true` is required because this repo
  hand-manages `xdg.configFile."nvim"` (recursively linked from
  `users/td/nvim/`). Home Manager's `withRuby`/`withPython3` options would
  otherwise try to write their own generated `init.lua` to the same path and
  get silently dropped (visible only as a "conflicts with recursively
  symlinked file" build warning) — `sideloadInitLua` loads that generated
  content via a wrapper `--cmd` flag instead, so both coexist.
- **lazy.nvim writes its lockfile to the repo, not `~/.config`.**
  `~/.config/nvim/lazy-lock.json` is a read-only store symlink, so a stock
  `:Lazy update` moves the installed plugins but cannot record them — this
  host drifts ahead of the lock the other hosts install from, invisibly.
  `users/td/nvim/lua/config/lazy.lua` sets `lockfile` to
  `/etc/nixos/users/td/nvim/lazy-lock.json` when that path is writable, so
  an update appears in `git status`: commit it, or `git checkout` the file
  and run `:Lazy restore` to roll the plugins back to it.

## Archives (`modules/desktop/default.nix`)

- **Dropping `p7zip` from `environment.systemPackages` does not remove it
  from the archive path.** `xarchiver` wraps itself with its own backends via
  `wrapProgram` at build time (`zip`, `unzip`, `p7zip`, `unar`, `gnutar`,
  `lhasa`, ...), so its `p7zip` stays on its private PATH regardless of what
  the system profile contains — and since `xdg.mimeApps` in `home.nix` points
  every archive MIME type at `xarchiver`, that wrapped copy is what actually
  opens a `.7z` from Thunar. Swapping the backend needs
  `xarchiver.override { p7zip = _7zz; }`, not just a list edit. Verify with:
  `strings $(readlink -f $(command -v xarchiver)) | grep -c p7zip` → expect 0.
- **`_7zz` drops in cleanly because xarchiver probes for `7zz` first.**
  `src/main.c` tries `7zz`, then `7z`, `7za`, `7zr` — and `_7zz` ships only a
  `7zz` binary, so no shim is needed. The reason to prefer it: `p7zip` is the
  `p7zip-project` fork pinned at 17.06 (upstream's last release; the repo
  itself last saw a push 2025-05-20) and nixpkgs carries **zero** patches on
  it, while official 7-Zip is on 26.x. Fixes such as CVE-2026-48095 (heap
  overflow in the NTFS handler, RCE, fixed in 7-Zip 26.01) are never coming
  to it. Compare `avahi`, also pinned at an ancient 0.8 but carrying ~20 CVE
  backports — old version alone isn't the smell, unpatched *and* old is.
- **`lhasa` is removed from xarchiver's wrapper the same way:**
  `lhasa = emptyDirectory` in the override. It parses LHA/LZH, a format
  nobody uses any more, and has no nixpkgs maintainers. xarchiver *also* has
  no maintainers, but it only runs the backend CLIs and never parses archive
  bytes itself, so the backends are what to check. Verify with:
  `strings $(readlink -f $(command -v xarchiver)) | grep -c lhasa` → expect 0.

## Deploying

- **The `rebuild` alias breaks on `utm-vm`.** `home.nix` defines
  `rebuild = "sudo nixos-rebuild switch --flake ."` — with no `#attr`,
  nixos-rebuild infers `nixosConfigurations.<current hostname>`. That VM's
  `networking.hostName` is `utm-nixos` while its flake attribute is
  `utm-vm`, so the bare form can't resolve an attr there. Use
  `sudo nixos-rebuild switch --flake .#utm-vm` (or `nh os switch .#utm-vm`)
  on that host. The alias is fine on `framework` and `dl-prototype`, where
  attr and hostname match.

## Deliberately left alone

- **tmux is intentionally unconfigured — do not theme it.** It's installed
  bare in `modules/core/default.nix` with no `programs.tmux` block, no
  `tmux.conf`, and no Tokyo Night styling, which makes it the only tool in
  this config running stock. That is the point: tmux gets used on machines
  where the config *can't* be edited (servers, other people's boxes), so the
  default `Ctrl+B` prefix and default status bar have to stay put or the
  muscle memory breaks the moment it's used off this machine. Local window
  management is Hyprland's job, not tmux's. A consistency pass over the rice
  will flag this — leave it.

## Misc

- **`gnome-keyring` vs `programs.ssh.startAgent`:** only one SSH agent can be
  active. `services.gnome.gnome-keyring.enable = true` defaults its own SSH
  agent piece on too; `modules/desktop/hyprland.nix` explicitly disables
  `services.gnome.gcr-ssh-agent.enable` so gnome-keyring only handles the
  secrets/login-credential portion, leaving the plain SSH agent as the only
  one running.
- **`utm-vm`'s `networking.hostName` is `"utm-nixos"`**, not `utm-vm` — see
  `docs/hosts.md`. Deploy with the flake attr `utm-vm`; don't expect
  `hostname` on that machine to print `utm-vm`.
- **Password-manager entries are kept out of clipboard history in two
  layers.** cliphist stores plaintext in `$XDG_CACHE_HOME/cliphist/db`, out
  of reach of KeePassXC's clear-clipboard timeout. KeePassXC advertises the
  extra MIME type `x-kde-passwordManagerHint` on the selections it copies.
  1. **Built in:** `wl-paste --watch` (wl-clipboard 2.3.0 as pinned) sets
     `CLIPBOARD_STATE=sensitive` for any offer carrying that type, and
     `cliphist store` does nothing in that state. This covers both
     watchers, text and image. Verified in the source of the pinned
     versions: `src/wl-paste.c` and cliphist 0.7.0's `cliphist.go`.
  2. **Explicit:** the text watcher in `hyprland.lua` also checks
     `wl-paste --list-types` for the hint before calling `cliphist store`,
     so the filter doesn't depend on both tools keeping that behaviour.
     Caveat: it re-queries the current selection rather than the event that
     woke it, so two copies within a few milliseconds can race. Layer 1
     doesn't have that race.

  `wl-clip-persist` is separate: its own documented
  `--all-mime-type-regex '^(?!x-kde-passwordManagerHint).+'` recipe stops
  it re-serving a password after KeePassXC lets go. It is deliberately on
  `--clipboard regular`, not `both`; upstream recommends against operating
  on the primary selection, which breaks text selection in GTK apps.
- **The cliphist db gets `umask 077` from all three cliphist commands.** cliphist
  creates it `0644`, and whichever command runs first after the file is
  deleted creates it. That's the two `wl-paste` watchers and the `SUPER+V`
  bind, so all three set `umask 077`. This only keeps other *users* out:
  anything running as `td` can still read it.
- **Syncthing's `overrideDevices`/`overrideFolders` are pinned `false`**
  (`modules/services/syncthing.nix`). Devices and folders are managed in the
  GUI. Both options default to `true`, which means "delete anything not
  declared in `services.syncthing.settings`". That is harmless only while
  nothing is declared, because the module skips its config push when
  `settings` is empty. Without the pin, adding the first
  `services.syncthing.settings.*` would silently wipe every GUI-added folder
  and device. Keep them `false` unless you move *all* devices and folders
  into Nix.
- **wttr.in TLS cert has been observed expired** — `waybar-weather` treats
  any fetch failure (cert or otherwise) as non-fatal and renders `"N/A"`
  rather than erroring the whole bar. If weather silently stops working,
  check wttr.in's cert status before assuming a config regression.
