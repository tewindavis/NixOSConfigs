# Security reference

The hardening this config applies, where each piece lives, and what it
costs. The code is the authority. Where a mechanism is already explained in
`docs/gotchas.md`, this file points to it rather than repeating it.

## Network exposure

| | framework | dl-prototype | utm-vm |
|---|---|---|---|
| TCP open | none | 22, 22000 | 22, 22000 |
| UDP open | none | 5353, 9001, 21027, 22000 | 5353, 9001, 21027, 22000 |
| sshd listens on | `127.0.0.1`, `::1` | all interfaces | all interfaces |

Regenerate the port rows with:

```bash
nix eval --json .#nixosConfigurations.<host>.config.networking.firewall \
  --apply 'f: { inherit (f) allowedTCPPorts allowedUDPPorts; }'
```

The ports come from `services.openssh.openFirewall` (22),
`services.syncthing.openDefaultPorts` (22000, 21027),
`services.avahi.openFirewall` (5353) and `modules/services/liftoff-telemetry.nix`
(9001: Telegraf receiving Liftoff telemetry). The syncthing and avahi options are
`mkDefault true` in their modules so that a host can turn them off.

**framework opens nothing** (`hosts/framework/configuration.nix`). It is the
laptop that joins untrusted LANs. An `assertions` entry fails evaluation, and
so fails `nix flake check`, if any module later:

- opens a port or port range, globally or per interface
- trusts an interface other than `lo` (e.g. `tailscale0`, which would accept
  every port on it)
- adds raw firewall rules that accept traffic. It checks `extraInputRules`,
  and `extraCommands` for "accept" in any case. `extraCommands` can't be
  required empty, because `nixos/nat` always writes its own cleanup there.

What closing everything costs on framework:

- Syncthing can only dial out to the other hosts or through relays.
- mDNS is closed, so `.local` names don't resolve.
- CUPS can't auto-discover network printers. Add them by IP.

## SSH (`modules/core/default.nix`)

- Key-only on every host: `PasswordAuthentication`,
  `KbdInteractiveAuthentication` off, `PermitRootLogin = "no"`.
- The authorized key lives in `users/td/nixos.nix`. It is the only way in
  over the network: an empty list means no remote access (the console is
  unaffected).
- framework: port 22 is closed, and `listenAddresses` binds sshd to loopback
  only, so the firewall isn't the only layer. sshd still runs because
  sops-nix decrypts with its host key, `/etc/ssh/ssh_host_ed25519_key` (see
  `docs/secrets.md`). `ssh localhost` works.

## Monitoring (dl-prototype, utm-vm)

- Prometheus, Grafana and the exporters listen on `127.0.0.1` only.
  Grafana is reached through SSH (`grafana-tunnel <host>`), so its login
  page is never on the network and SSH keys are the gate.
- Grafana's admin password and secret key are generated on the host at
  first start (`grafana-secrets` in `modules/services/monitoring.nix`) into
  `/var/lib/grafana-secrets` (`0700`, owned by `grafana`). They never enter
  the repo or the Nix store. These hosts aren't sops recipients.
- Grafana's usage reporting, update checks and news feed are off.
- UDP 9001 is open for Liftoff telemetry. Telegraf only accepts exact
  80-byte packets and decodes them as 20 floats; anything else is dropped.
  Anyone who can reach the port can write fake telemetry into the charts,
  nothing more. The port is on every interface, so on dl-prototype it's the
  LAN; on utm-vm it depends on UTM's network mode.
- Prometheus's remote-write receiver is on (Telegraf pushes into it), but
  only on `127.0.0.1`, so only local processes can write.

## Script state

The shell scripts in `home.nix` (`toggle-recording`, `toggle-blackout`,
`waybar-hyprsunset`, `waybar-cava`, `idle-dim`) keep their state in
`$XDG_RUNTIME_DIR` (`/run/user/<uid>`: `0700`, cleared at logout), never at
fixed names in the shared `/tmp`. `idle-dim` exists for this: `brightnessctl
-s`/`-r` would save under brightnessctl's own fixed `/tmp/brightnessctl/`.
Scripts that signal a PID from a file (`toggle-recording`, `waybar-cava`)
first check `/proc/<pid>/cmdline`, so a stale file can't hit an unrelated
process.

## Name resolution and discovery

- **systemd-resolved** (enabled in `modules/services/vpn.nix`, all hosts):
  `LLMNR` and `MulticastDNS` are off. LLMNR is the protocol Responder-style
  spoofing attacks target on shared LANs, and it sends every failed
  single-label lookup onto the network. Avahi already handles mDNS, so
  resolved's responder was a duplicate. Check with
  `resolvectl status | grep Protocols`, which should show `-LLMNR -mDNS`.
- **cups-browsed** is off on every host (`services.printing.browsed.enable`
  in `modules/core/default.nix`). It auto-creates a queue for every printer
  advertised on the LAN, which was the entry point of the 2024
  cups-browsed/foomatic-rip RCE chain. CUPS itself is built with DNS-SD, so
  on hosts with mDNS open, print dialogs still list AirPrint/IPP Everywhere
  printers as temporary queues.

## Boot and disk

- `boot.loader.systemd-boot.editor = false` on all three hosts. The editor
  lets anyone at the boot menu append `init=/bin/sh`.
- framework's root is LUKS-encrypted (`hardware-configuration.nix`), so there
  the editor was a tampering path. dl-prototype's and utm-vm's roots are not
  encrypted, so on those hosts the disabled editor is the only barrier
  between the boot menu and a root shell.
- All hosts use the systemd initrd (`boot.initrd.systemd.enable`, for the
  plymouth splash in `modules/core/default.nix`). Its emergency shell stays
  off: `boot.initrd.systemd.emergencyAccess` is left at its default,
  `false`, so a failed boot doesn't drop to a root shell in the initrd. Setting
  it to `true` would make that another path to root on the unencrypted hosts.

## Local authentication (framework)

`services.fprintd.enable = true` makes `security.pam.services.<name>.fprintAuth`
default to `true` for **every** PAM service, not just the three set
explicitly in `modules/hardware/framework.nix`. The built `/etc/pam.d`
includes `pam_fprintd` as `sufficient` in `sudo`, `su`, `run0`
(`systemd-run0`), `polkit-1` (GUI admin prompts), `login` (which `greetd`
substacks) and `hyprlock`, among others. So a fingerprint alone authorizes
root. List the affected services with:

```bash
grep -l pam_fprintd /etc/pam.d/*
```

To exclude a service, set its `fprintAuth = false` explicitly.

## Clipboard

- KeePassXC entries are kept out of `cliphist` history (by wl-paste's
  `CLIPBOARD_STATE=sensitive` plus an explicit guard in the watcher) and out
  of `wl-clip-persist`. The mechanism is in `docs/gotchas.md` (Misc). To verify: copy a password from KeePassXC, then
  run `cliphist list`. The password must not appear, but ordinary copied text
  must.
- The history db is created `0600` (`umask 077` on every cliphist caller;
  also in `docs/gotchas.md`).
- swaync's notification-2fa-action is left on (its default): notifications
  that contain a code get a "COPY" button. Clicking it puts the code on the
  clipboard like any copy, so it lands in `cliphist` history. Nothing is
  copied unless you click.

## Untrusted input

- Archives: `xarchiver` handles every archive MIME type, so its wrapped
  backends are what parse hostile files. `p7zip` is replaced by official
  7-Zip (`_7zz`) and `lhasa` is removed. See `docs/gotchas.md` (Archives).
- Neovim: `markdown-preview.nvim` is disabled because its build step
  downloads an unsigned binary from a dormant repo. See `docs/gotchas.md`
  (Neovim / LazyVim).

## Untrusted text rendered as markup

Waybar, hyprlock and swaync render Pango markup, so text from outside must
be escaped before it reaches them.

- Weather comes from wttr.in: `custom/weather` has `"escape": true`, and
  the hyprlock label pipes it through `jq '.text | @html'`. Waybar custom
  modules do *not* escape by default.
- Track titles (web pages set these through Brave's media session): waybar's
  `mpris` module escapes them itself; `hyprlock-nowplaying` escapes `&`,
  `<`, `>` with sed.

## Supply chain

- Every flake input follows the root `nixpkgs`, so `flake.lock` holds a
  single nixpkgs. `checks.single-nixpkgs` (`scripts/check-single-nixpkgs.sh`)
  fails `nix flake check` if a second copy appears, and names the input that
  pulled it in.
- Ghostty comes from nixpkgs, not the upstream `ghostty` flake. That flake
  built unreleased git main from source and brought in its own nixpkgs,
  home-manager, a Zig overlay and `zon2nix`, all of which ran at build time.
- Neovim fetches at runtime, outside Nix, in three ways:
  - lazy.nvim clones plugins from GitHub at the commits pinned in
    `users/td/nvim/lazy-lock.json`. `:Lazy update` records changes into the
    repo.
  - nvim-treesitter downloads and compiles parser sources.
  - `blink.cmp` downloads a prebuilt native library from its GitHub release
    and loads it into nvim. It is checksummed against that same release,
    not signed.

  Details are in `docs/gotchas.md` (Neovim / LazyVim).
- QGIS and GRASS can install code at runtime, outside Nix: QGIS's plugin
  manager downloads Python plugins from plugins.qgis.org (run inside
  QGIS), and GRASS's `g.extension` downloads add-ons from GitHub and
  compiles them. Nothing is installed unless you ask for it.
- Qt apps load the `qt5ct` platform-theme plugin (`qt.platformTheme.name =
  "qtct"`), which runs inside each app's process. `libsForQt5.qt5ct` has
  no nixpkgs maintainer (a SourceForge tarball, no patches), so KeePassXC
  is launched without it: `home.nix` wraps `keepassxc` to unset
  `QT_QPA_PLATFORMTHEME`/`QT_STYLE_OVERRIDE`, and the password manager loads
  only Qt's own plugins. Verify with
  `QT_DEBUG_PLUGINS=1 keepassxc 2>&1 | grep 'loaded library.*platformthemes'`
  (no output expected).

## Known gaps, not addressed

These have been identified but not acted on.

- **`/etc/nixos` is owned by `td`.** Anything running as `td` (nvim plugins,
  npm/cargo build scripts, AI CLIs) can edit the config that root builds and
  activates on the next switch, and `nh`'s diff shows the resulting packages,
  not the source edit. Review `git status` / `git diff` before switching.
- **Syncthing's web GUI** listens on `127.0.0.1:8384`. Its password is
  GUI-managed state in `~/.config/syncthing/config.xml`, not declared in Nix.
- **The mic indicator can be dodged by name.** Waybar's `privacy` module
  ignores any audio-capture stream whose PipeWire `node.name` is `cava`
  (the visualizer's own capture), and any program running as `td` can pick
  that name. Web pages can't set it, so this only matters against local
  software, which could equally stop waybar.
