# Security reference

The hardening this config applies, where each piece lives, and what it
costs. The code is the authority. Where a mechanism is already explained in
`docs/gotchas.md`, this file points to it rather than repeating it.

## Network exposure

| | framework | dl-prototype | utm-vm |
|---|---|---|---|
| TCP open | none | 22, 22000 | 22, 22000 |
| UDP open | none | 5353, 21027, 22000 | 5353, 21027, 22000 |
| sshd listens on | `127.0.0.1`, `::1` | all interfaces | all interfaces |

Regenerate the port rows with:

```bash
nix eval --json .#nixosConfigurations.<host>.config.networking.firewall \
  --apply 'f: { inherit (f) allowedTCPPorts allowedUDPPorts; }'
```

The ports come from `services.openssh.openFirewall` (22),
`services.syncthing.openDefaultPorts` (22000, 21027) and
`services.avahi.openFirewall` (5353). The syncthing and avahi options are
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

- KeePassXC entries are kept out of `cliphist` history and out of
  `wl-clip-persist`. The mechanism, and its race caveat, are in
  `docs/gotchas.md` (Misc). To verify: copy a password from KeePassXC, then
  run `cliphist list`. The password must not appear, but ordinary copied text
  must.
- The history db is created `0600` (`umask 077` on every cliphist caller;
  also in `docs/gotchas.md`).

## Untrusted input

- Archives: `xarchiver` handles every archive MIME type, so its wrapped
  backends are what parse hostile files. `p7zip` is replaced by official
  7-Zip (`_7zz`) and `lhasa` is removed. See `docs/gotchas.md` (Archives).
- Neovim: `markdown-preview.nvim` is disabled because its build step
  downloads an unsigned binary from a dormant repo. See `docs/gotchas.md`
  (Neovim / LazyVim).

## Supply chain

- Every flake input follows the root `nixpkgs`, so `flake.lock` holds a
  single nixpkgs. Check with `jq -r '.nodes | keys[]' flake.lock`. A second
  `nixpkgs_*` node means an input stopped following.
- Ghostty comes from nixpkgs, not the upstream `ghostty` flake. That flake
  built unreleased git main from source and brought in its own nixpkgs,
  home-manager, a Zig overlay and `zon2nix`, all of which ran at build time.
- Neovim plugins are the one runtime fetch: lazy.nvim clones them from GitHub
  at the commits pinned in `users/td/nvim/lazy-lock.json`, and `:Lazy update`
  records changes into the repo (see `docs/gotchas.md`).

## Known gaps, not addressed

These have been identified but not acted on.

- **`/etc/nixos` is owned by `td`.** Anything running as `td` (nvim plugins,
  npm/cargo build scripts, AI CLIs) can edit the config that root builds and
  activates on the next switch, and `nh`'s diff shows the resulting packages,
  not the source edit. Review `git status` / `git diff` before switching.
- **Syncthing's web GUI** listens on `127.0.0.1:8384`. Its password is
  GUI-managed state in `~/.config/syncthing/config.xml`, not declared in Nix.
- **Fixed `/tmp` paths:** `toggle-recording` (a pidfile it later `kill`s,
  plus its log), `toggle-blackout` and `waybar-hyprsunset` keep state at
  fixed names under `/tmp` rather than in `$XDG_RUNTIME_DIR`. There is only one
  human account and `fs.protected_symlinks` is on, so this is hygiene, not an
  open hole.
