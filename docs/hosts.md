# Hosts reference

Each host's `configuration.nix` is an import list + a handful of host-only
settings. This table is the module-wiring source of truth — check it before
assuming a module applies everywhere.

| Module | framework | dl-prototype | utm-vm |
|---|:---:|:---:|:---:|
| `modules/core` | ✓ | ✓ | ✓ |
| `modules/desktop` (Hyprland/Thunar/fonts) | ✓ | ✓ | ✓ |
| `modules/services/vpn.nix` | ✓ | ✓ | ✓ |
| `modules/services/syncthing.nix` | ✓ | ✓ | ✓ |
| `modules/hardware/bluetooth.nix` | ✓ | ✓ | — |
| `modules/hardware/framework.nix` (nixos-hardware 7040-amd, fprintd, fwupd, power-profiles, bolt, 80% charge cap) | ✓ | — | — |
| `modules/hardware/nvidia.nix` | — | ✓ | — |
| `modules/hardware/utm.nix` (QEMU/Spice guest) | — | — | ✓ |
| `modules/dev/rl-binary.nix` (ghidra/radare2/gdb + RL Python) | — | ✓ | — |
| `modules/services/training-metrics.nix` (node + NVIDIA GPU exporters, training dashboards; imports `monitoring.nix`) | — | ✓ | — |
| `modules/services/liftoff-telemetry.nix` (Liftoff UDP telemetry → Telegraf → Prometheus, dashboard; imports `monitoring.nix`) | — | ✓ | ✓ |

`modules/services/monitoring.nix` (local-only Prometheus + Grafana) isn't
imported by hosts directly; the two modules above pull it in.

Bluetooth is skipped on `utm-vm` because it's a VM with no Bluetooth
hardware to manage.

## framework

- `networking.hostName = "framework"` — the only host currently enrolled as
  a sops-nix age recipient (see `docs/secrets.md`).
- Fingerprint auth (`fprintd`). Enabling it turns on `pam_fprintd` for
  *every* PAM service, sudo and polkit included, not only the three
  `fprintAuth` lines in `modules/hardware/framework.nix`. See
  `docs/security.md`.
- No inbound ports, sshd bound to loopback, and an `assertions` entry in its
  `configuration.nix` that fails evaluation if anything opens a port. Details
  and costs (Syncthing dials out only; no `.local` names or printer
  discovery) are in `docs/security.md`.
- LUKS-encrypted root (`hardware-configuration.nix`), the only host with one.
- `power-profiles-daemon` enabled (balanced/power-saver/performance); waybar's
  power-profile widget only does something useful here — on the other two
  hosts it reports "unavailable" and degrades gracefully.
- HiDPI: `hyprland.lua` special-cases this hostname to force
  `mode = "2256x1504@60"`, `scale = 1.175` (the exact divisor for a clean
  1920x1280 logical resolution) on `eDP-1` only. The same branch pins the two
  docked Dell S2725QCs by serial (`desc:`), with mode, position, scale and the
  portrait one's `transform`, and gives any other display
  `mode = "preferred"`, `scale = "auto"`. Every other host uses that
  preferred/auto rule for all outputs.
- `services.hardware.bolt` (in `modules/hardware/framework.nix`): the
  Thunderbolt controller's security level is `user`, so docks stay
  unauthorized until bolt approves them. Enroll a new dock once with
  `boltctl enroll --policy auto <uuid>` (`boltctl list` shows the uuid).
- `modules/hardware/framework.nix` imports `nixos-hardware`'s
  `framework-13-7040-amd` module (`/sys/class/dmi/id/product_name` reads
  "Laptop 13 (AMD Ryzen 7040Series)"; `/proc/cpuinfo` gives the Ryzen 7
  7840U). Beyond pstate/amdgpu/microcode it adds the `amdgpu.dcdebugmask=0x10`
  kernel param (disables panel self-refresh, a known hang source), the
  out-of-tree `framework-laptop-kmod` EC module and `framework-tool`. The
  `nixos-hardware` input follows our `nixpkgs`, so it adds no third nixpkgs to
  the lock.

## dl-prototype

- AMD Threadripper: `hardware.cpu.amd.updateMicrocode = true`,
  `powerManagement.cpuFreqGovernor = "performance"`.
- NVIDIA proprietary driver (`modules/hardware/nvidia.nix`): modesetting on,
  `open = false` (proprietary, not the open kernel module),
  and both power-management knobs off deliberately, not by oversight:
  `powerManagement.enable = false` (experimental; can cause sleep/suspend to
  fail) and `powerManagement.finegrained = false` (experimental, and only
  works on Turing-or-newer GPUs). `nvtop` included for live GPU/VRAM
  monitoring.
- `modules/dev/rl-binary.nix`: binary-analysis toolkit (ghidra, radare2, gdb,
  gef — not pwndbg, which isn't a real nixpkgs package) plus a CPU-focused RL
  Python env (`stable-baselines3` + `gymnasium`, both patched with
  `doCheck = false` — see `docs/gotchas.md`).
- Not yet sops-enrolled — see `docs/secrets.md` before declaring any
  `sops.secrets.*` here.
- Monitoring: Prometheus and Grafana on 127.0.0.1 (view with
  `grafana-tunnel dl-prototype`; admin password in
  `/var/lib/grafana-secrets/admin_password`), fed by `node_exporter`, the
  NVIDIA GPU exporter and Liftoff telemetry on UDP 9001.
- Training runs: pass `sb3_prometheus.PrometheusCallback(run="name")` to
  `model.learn(...)` (package in `modules/dev/rl-binary.nix`). Everything
  stable-baselines3 logs (reward, episode length, fps, losses) is served on
  `127.0.0.1:9435` and charted in Grafana's *Training run* dashboard next to
  GPU use.
- Root filesystem is not encrypted. Port 22 (key-only), Syncthing, mDNS and
  UDP 9001 (Liftoff telemetry) are open; see `docs/security.md`.

### First deploy checklist

The config is complete except for the hardware file, so bringing the
machine up is mostly ordering:

1. Install NixOS from the installer ISO (partitioning, and whether to
   encrypt the root: framework does, this host's config doesn't assume it).
2. On the machine, run `nixos-generate-config --show-hardware-config` and
   replace the placeholder `hosts/dl-prototype/hardware-configuration.nix`
   with its output. The placeholder's all-zero root UUID won't boot.
3. Check the GPU generation before the first switch: `open = false` in
   `modules/hardware/nvidia.nix` is the proprietary module; the open one is
   an option only on Turing (RTX 20) or newer. See `docs/gotchas.md`.
4. Deploy with the explicit attr: `sudo nixos-rebuild switch --flake
   .#dl-prototype`. SSH comes up key-only with `td`'s key from
   `users/td/nixos.nix`.
5. If it will hold secrets, enroll it in sops first (`docs/secrets.md`,
   "Enroll a new host"), including `sops updatekeys`, run from framework. Nothing here needs a
   secret yet: Grafana generates its own on first start.
6. Check the monitoring came up: `systemctl status prometheus grafana
   grafana-secrets prometheus-node-exporter prometheus-nvidia-gpu-exporter
   telegraf`, then from the laptop `grafana-tunnel dl-prototype` and log in
   as `admin` with `sudo cat /var/lib/grafana-secrets/admin_password`.
7. Pair Syncthing devices in its GUI (devices and folders are GUI-managed,
   see `docs/gotchas.md`).

## utm-vm

- `networking.hostName = "utm-nixos"` — note this **does not match** the
  flake attribute name `utm-vm` used in `flake.nix`/`hosts/utm-vm/`. Deploy
  with `nixos-rebuild switch --flake .#utm-vm`; the running system reports
  itself as `utm-nixos`. Consequence: the bare `rebuild` alias from
  `home.nix` (`nixos-rebuild switch --flake .`, no attr) **fails on this
  host**, because it infers the attr from the hostname — see
  `docs/gotchas.md`. Don't "fix" the mismatch without checking whether
  anything depends on the hostname string.
- `modules/hardware/utm.nix`: QEMU guest agent, Spice vdagent (clipboard +
  resolution scaling), `virtio_gpu` forced into the initrd, `virtio` video
  driver.
- No bluetooth, no fingerprint, no NVIDIA — smallest hardware surface of the
  three.
- Liftoff telemetry: the game on the Mac sends to this VM's UDP 9001;
  view the dashboard with `grafana-tunnel utm-nixos` (Prometheus and
  Grafana on 127.0.0.1; admin password in
  `/var/lib/grafana-secrets/admin_password`).
- Root filesystem is not encrypted. Port 22 (key-only), Syncthing, mDNS and
  UDP 9001 (Liftoff telemetry) are open; see `docs/security.md`.
