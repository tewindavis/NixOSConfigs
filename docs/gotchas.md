# Gotchas and tribal knowledge

Non-obvious bugs and constraints already hit and fixed in this repo, mined
from code comments and commit history. Check here before re-debugging one of
these from scratch.

## Hyprland 0.56+ / hyprland.lua

- **Config format:** 0.56+ treats the old `.conf`/hyprlang syntax as
  *legacy* and looks for `hyprland.lua` first. This repo already migrated
  (2026-09-15) — don't add a `hyprland.conf`.
- **Dispatch args are Lua expressions, not strings.** Plain
  `hyprctl dispatch <dispatcher> <args>` no longer works on this version.
  Correct form, confirmed live:
  `hyprctl dispatch 'hl.dsp.window.float()'`,
  `hyprctl dispatch 'hl.dsp.dpms(false)'`,
  `hyprctl dispatch 'hl.dsp.workspace.toggle_special("scratchpad")'`. All the
  custom scripts in `home.nix` (`toggle-scratchpad`, hypridle DPMS listeners)
  already use this form — copy their pattern for new dispatch calls rather
  than the classic `hyprctl dispatch <name> <arg>` syntax from older docs.
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
  `false` deliberately — finegrained power management is experimental and
  "can cause sleep/suspend to fail" on this driver stack. Don't flip these on
  without testing suspend/resume specifically.
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
- Both `gymnasium` and `stable-baselines3` are overridden with
  `doCheck = false`. Reason: their `nativeCheckInputs` transitively pull in
  `tensorflow` (via flax → keras → tf-keras), and tensorflow is marked
  broken in this nixpkgs pin. `gymnasium` is patched *before* being passed
  into `stable-baselines3.override { gymnasium = ...; }` — patching it as a
  sibling package instead would not retroactively fix
  `stable-baselines3`'s own `propagatedBuildInputs` reference to the
  unpatched version.

## Neovim / LazyVim

- LSPs/formatters/linters are installed via Nix in `home.nix` (grouped by
  LazyVim language extra in comments there), **not** via Mason — Mason is
  explicitly disabled in `users/td/nvim/lua/plugins/mason.lua` so editor
  tooling stays reproducible via `nixos-rebuild` instead of drifting from
  whatever Mason downloaded at runtime. When adding language support, add
  the LSP/formatter package to `home.nix`, don't rely on `:Mason` to install
  it.
- `programs.neovim.sideloadInitLua = true` is required because this repo
  hand-manages `xdg.configFile."nvim"` (recursively linked from
  `users/td/nvim/`). Home Manager's `withRuby`/`withPython3` options would
  otherwise try to write their own generated `init.lua` to the same path and
  get silently dropped (visible only as a "conflicts with recursively
  symlinked file" build warning) — `sideloadInitLua` loads that generated
  content via a wrapper `--cmd` flag instead, so both coexist.

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

Other things that look unfinished but aren't, documented where they live:
the kanshi `CHANGE_ME` output placeholder (`docs/desktop.md`) and the
commented-out `nixos-hardware` import for Framework (`docs/hosts.md`).

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
- **wttr.in TLS cert has been observed expired** — `waybar-weather` treats
  any fetch failure (cert or otherwise) as non-fatal and renders `"N/A"`
  rather than erroring the whole bar. If weather silently stops working,
  check wttr.in's cert status before assuming a config regression.
