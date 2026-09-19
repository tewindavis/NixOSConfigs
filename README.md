# NixOS Golden State: Multi-System Architecture
**Architect & Implementer:** Google Gemini (2026)
**Contributor:** Claude Code (Sonnet 5, 2026)

This repository contains a professional-grade, highly modular NixOS configuration managed via Flakes. It is designed to provide a unified "Golden State" developer experience across three distinct hardware profiles, featuring a high-saturation "riced" desktop and a pre-equipped toolkit for modern engineering.

---

## 🖥️ Target Architectures

The system uses a modular extraction pattern (`modules/hardware/`) to isolate host-specific logic, ensuring that software configurations remain pure and portable.

*   **`utm-vm`:** Aarch64 sandbox optimized for MacOS/Apple Silicon. Features VirtIO graphics and Spice guest integration.
*   **`framework`:** Primary x86_64 portable workstation. Optimized for Framework 13 hardware, including HiDPI scaling (1.175), fingerprint authentication (`fprintd`, accepted at every PAM prompt: login, lock screen, `sudo`, polkit), and firmware updates via `fwupd`.
*   **`dl-prototype`:** High-performance x86_64 training rig. Configured for AMD Threadripper CPU optimization and NVIDIA proprietary driver support.

---

## 🔒 Security Baseline

Hardened by default on every host. The full reference, with the cost of each choice, is `docs/security.md`.

*   **SSH:** key-only, no root login. `framework`, the roaming laptop, opens no inbound ports at all and binds `sshd` to loopback. If any module later opens a port, the build fails.
*   **Boot:** the systemd-boot kernel-command-line editor is disabled, so the boot menu can't be used to get a root shell. `framework`'s root is LUKS-encrypted.
*   **Quiet on the LAN:** systemd-resolved's LLMNR and mDNS are off, and `cups-browsed` is disabled, so printers advertised on the LAN are never added automatically. Print dialogs still list network printers on hosts where mDNS is open.
*   **Passwords stay out of clipboard history:** entries copied from KeePassXC are never written to `cliphist`, and the history file is private (`0600`).
*   **Hostile files:** archives go through the official 7-Zip rather than the abandoned `p7zip` fork, and the unmaintained LHA backend is removed.
*   **Supply chain:** every flake input shares one pinned `nixpkgs`, and `nix flake check` fails if that changes. Neovim plugins are pinned by `lazy-lock.json`. `markdown-preview.nvim`, which downloaded an unsigned binary from a dormant repo, is disabled. `blink.cmp` still downloads its prebuilt fuzzy-matcher library; see `docs/security.md`.

---

## 🎨 The "Tokyo Night" Aesthetic

The desktop environment is built on the **Tokyo Night (Night)** color palette, optimized for high contrast and vibrant visual energy without pastel washout.

*   **Vibrant Glass:** Windows default to a frosted-glass aesthetic (90% active / 80% inactive opacity over a 6-size, 3-pass blur with a touch of vibrancy and noise), with soft shadows. Waybar, wofi, notifications and the swayosd OSD are blurred too, via layer rules. Two exceptions: Ghostty is a touch more translucent (its window rule multiplies on top of that, plus its own background opacity), and Brave is forced fully opaque.
*   **Complementary Spectrum:** Status modules and UI accents use a bold spectrum: **Blue** (#7aa2f7) for identity, **Green** (#9ece6a) for location, and **Orange** (#ff9e64) for status.
*   **Automated Art:** The `setup-wallpapers` script fetches a starter Hyprchan wallpaper into `~/Pictures/Wallpapers` on first login (it runs at every Hyprland start but skips a file that's already there); drop in more images and `cycle-wallpaper` (`SUPER + W`) gives each monitor its own random pick from the folder, growing out from the cursor.
*   **Themed Lock & Notifications:** `hyprlock` (with a live clock, date, weather, battery, now-playing track, and Fingerprint-or-Password prompt), `swaync` notifications, the `swayosd` volume/brightness OSD, and the `wlogout` power menu are all styled to match the Waybar/Wofi palette — dark translucent panels, blue borders, and urgency-tiered accent colors, including a recolored `wlogout` icon set (blue lock/logout, green suspend/hibernate, orange reboot, red shutdown).
*   **Idle Inhibitor:** A clickable Waybar toggle (right of the volume module) suspends `hypridle`'s auto-lock/DPMS while active — turns red when suppressing.
*   **Idle Warning:** The laptop panel dims to 10% at 4:30 idle, 30 seconds before the 5-minute lock; any input restores the brightness.
*   **Workspace Buttons:** Each bar shows only its own monitor's workspaces that have windows in them, each with icons of the apps it holds.
*   **A Bar Per Monitor:** Every bar except the portrait Dell's shows now-playing media and an inline `cava` audio visualizer (click it to turn it off; a dim note icon stays to turn it back on). The laptop panel leaves out CPU/memory to save battery, the portrait Dell gets a slim bar (workspaces + clock), and everything else gets the full bar.
*   **Privacy & Notifications:** A red Waybar indicator appears while the screen is being shared or the mic is recording. Notifications come from `swaync`: its bell in Waybar turns blue for unread ones, click it (or `SUPER + N`) for a notification center with history, a do-not-disturb switch and media controls, and right-click it to toggle do not disturb.
*   **Motion:** Workspaces slide-and-fade, the scratchpad drops down from the top (dimming what's behind it), and the active border's blue→green gradient slowly rotates. Notifications slide in from the right and the launcher pops in. `SUPER + W` wallpapers grow outward from the cursor.
*   **Overview & Switcher:** `SUPER + Tab` opens a `hyprshell` overview of every workspace and its windows with a built-in launcher (apps by usage, calculator, web search, power actions). `ALT + Tab` is a Windows-style switcher: most recently used first, hold Alt and tap Tab, release to switch. Both are themed and blurred to match.
*   **Shape & Layout:** Windows use the same 12px corner radius as the bar, launcher and notifications. Pop-up utilities (volume, Bluetooth, network, image viewer) float centered instead of squashing the tiled layout, and `SUPER + G` turns windows into tabbed groups with a palette-colored tab bar.
*   **Boot to Desktop:** A Plymouth splash (Catppuccin Mocha) with silent boot, including the LUKS prompt on framework, then a Tokyo Night–themed `tuigreet` headed with the machine's name and NixOS release. The TTY palette matches Ghostty's.
*   **Themed CLI:** `bat`, `fzf`, `bottom`, `zathura`, `eza` (via `vivid`) and zsh's syntax highlighting and autosuggestions all use the same palette. Starship's right side shows how long slow (2s+) commands took and the time, and Ghostty draws a short fading trail when the cursor jumps.
*   **Window Swallowing:** A graphical app started from a Ghostty window (an `xdg-open`ed PDF, `mpv`, `imv`, anything) takes that window's place until it closes.
*   **Themed Git Diffs:** `git diff`/`log -p`/`show` go through `delta`: side-by-side, line numbers, tokyonight syntax and diff colors.
*   **Themed Qt Apps:** syncthingtray and Octave get the palette through `qt5ct`/`qt6ct` with the Fusion style. KeePassXC is deliberately left out (no third-party theme plugin inside the password manager) and uses its own built-in Dark theme.
*   **Themed GTK Apps:** Thunar, pavucontrol, Bluetooth and network settings and other GTK3/GTK4 apps use the palette too (darker header bars and sidebars, blue accents).
*   **Weather:** A Waybar module next to the clock shows current conditions via `wttr.in`, with a graceful "N/A" fallback if the network or upstream service is unavailable.
*   **Auto Blue-Light Filter:** `hyprsunset` runs as a daemon on login and switches itself between neutral (7:30am) and warm 2450K (8:00pm) — f.lux/redshift-style — per the schedule in `hyprsunset.conf`. A Waybar toggle (sun/moon icon, next to the idle inhibitor) shows and flips the current state; `SUPER + R`/`SUPER + SHIFT + R` do the same from the keyboard. Any of the three count as a manual override until the next scheduled switch.

---

## ⌨️ Hyprland Cheat Sheet

System controls are bound to the **`SUPER`** (Command) key, apart from `Print` and the media keys.

### Applications & Navigation
| Key | Action |
|:--- |:---|
| `SUPER + T` or `SUPER + Return` | Open Ghostty Terminal |
| `SUPER + Space` | Launch Application Menu (Wofi) |
| `SUPER + E` | Open File Manager (Thunar) |
| `SUPER + X` | Kill Active Window |
| `SUPER + H/J/K/L` | Move Focus (Vim-style) |
| `SUPER + Tab` | Overview: every workspace and its windows, plus a launcher (type to search apps, calculate, web search); Tab/Return to pick (`hyprshell`) |
| `ALT + Tab` / `ALT + SHIFT + Tab` / `ALT + Grave` | Windows-style switcher: hold Alt, recently used first, release to switch (`hyprshell`) |
| `SUPER + 1-9` | Switch Workspace |
| `SUPER + SHIFT + 1-9` | Move Window to Workspace |
| `SUPER + F` | Toggle Fullscreen |
| `SUPER + P` | Toggle Pseudotile |
| `SUPER + SHIFT + Space` | Toggle Floating |
| `SUPER + S` | Toggle Dropdown Scratchpad Terminal |
| `SUPER + G` | Toggle Tabbed Group (new windows join the focused group) |
| `SUPER + CTRL + Tab` / `SUPER + CTRL + SHIFT + Tab` | Next / Previous Tab in Group |
| `SUPER + CTRL + H/J/K/L` | Move Window Into Neighbouring Group (or out of its own) |
| `SUPER + SHIFT + E` | Exit Hyprland |
| `3-Finger Swipe` | Switch Workspace (Gesture) |

### System & Hardware
| Key | Action |
|:--- |:---|
| `SUPER + SHIFT + L` | Lock Screen (Heavy Blur) |
| `SUPER + SHIFT + S` | Screenshot Region → opens `swappy` to annotate (its toolbar does the copy/save) |
| `Print` | Screenshot Full Output (instant Copy + Save) |
| `SUPER + ALT + R` | Toggle Screen Recording (mp4, `~/Videos/Recordings`) |
| `SUPER + C` | Pick Color Under Cursor (`hyprpicker`, copies to clipboard) |
| `SUPER + V` | Clipboard History |
| `SUPER + Period` | Emoji Picker (types it and copies it) |
| `SUPER + N` | Toggle Notification Center (`swaync`) |
| `SUPER + SHIFT + P` | Power Menu |
| `SUPER + W` | Cycle Wallpaper |
| `SUPER + SHIFT + W` | Toggle Blackout Wallpaper (solid black, for glare relief) |
| `SUPER + R` | Manual Override: Aggressive Hyprsunset (2500K) |
| `SUPER + SHIFT + R` | Manual Override: Reset Hyprsunset (Day Mode) |
| `SUPER + Left Click` | **Drag to Move** Window |
| `SUPER + Right Click`| **Drag to Resize** Window |
| `Media Keys` | Volume, Mic, and Brightness Control (with on-screen display); Play/Pause, Next, Previous (`playerctl`) |

---

## 🛠️ The Developer Toolkit

The environment is "ready-to-code" immediately upon login, featuring a modern Zsh shell and a full compiler stack.

*   **Languages:** Rust (Cargo/Rustc/Rustlings), Zig (ZLS), Julia, Lua, Octave, C/C++, and Python 3.
*   **Modern Shell:** Zsh is the default shell, featuring syntax highlighting, auto-suggestions, and the **Starship** Powerline prompt.
*   **CLI Essentials:** `ripgrep`, `fd`, `bat` (cat), `eza` (ls), `zoxide` (cd), `gh` (GitHub CLI), and `direnv` for automatic flake environment loading.
*   **Media & Printing:** `mpv` handles video/audio opened from Thunar; CUPS + Avahi provide zero-config discovery and printing to network/AirPrint printers, managed via `system-config-printer` (discovery is off on `framework`, which opens no inbound ports; add printers there by IP).
*   **Screen Sharing:** `xdg-desktop-portal-hyprland` is wired in alongside the GTK portal, so screen/window capture works in Brave and any other portal-aware app.
*   **Screen Recording:** `SUPER + ALT + R` toggles `wf-recorder` in the background, saving timestamped mp4s to `~/Videos/Recordings` with a start/stop notification.
*   **Archives:** `xarchiver` (Thunar's archive-plugin backend) plus `_7zz`/`unrar`/`zip`/`unzip` handle zip/7z/rar/tar/gzip out of the box. `_7zz` is the official 7-Zip CLI rather than the abandoned `p7zip` fork, and `xarchiver` is overridden to use it as its 7z backend too — see `docs/gotchas.md`.
*   **Password Manager:** `keepassxc` is the default handler for `.kdbx` files. Passwords copied from it are kept out of `SUPER + V` clipboard history.
*   **File Sync:** `syncthing` runs as a system service (LAN/P2P sync), with `syncthingtray` in the waybar tray for status/control; `rclone` is available for cloud-storage remotes.
*   **System Monitor:** `resources`, a GTK4/libadwaita system monitor, complements the CLI `htop`/`bottom`.
*   **Firmware:** `gnome-firmware` gives a GUI alongside `fwupdmgr` for firmware updates (the `fwupd` daemon only runs on `framework`).
*   **Monitoring (dl-prototype, utm-vm):** Prometheus + Grafana, local-only, opened from any machine with `grafana-tunnel <host>` (an SSH tunnel). dl-prototype charts CPU, RAM, disk, network and NVIDIA GPU use during training, and the training itself: pass `PrometheusCallback(run="name")` from `sb3_prometheus` to a stable-baselines3 `learn()` and reward, episode length, fps and losses appear in a *Training run* dashboard. Both hosts also chart *Liftoff* FPV-drone telemetry: copy `modules/services/liftoff/TelemetryConfiguration.json` into Liftoff's data folder (macOS: `~/Library/Application Support/LuGus Studios/Liftoff/`) with `HOST_IP` set to the receiving host, and the game streams sticks, gyro rates, speed, altitude and battery to a live dashboard.
*   **GIS:** QGIS (long-term release, `qgis-ltr`) and GRASS GIS (`grass`) as separate apps. GRASS's algorithms appear in QGIS's Processing toolbox once the bundled **GRASS GIS provider** plugin is enabled (Plugins → Manage and Install Plugins → Installed; it's off by default). QGIS's native GRASS plugin isn't included: that build isn't in the binary cache.
*   **AI Integration:** `claude-code` and `antigravity-cli` are pre-installed for agentic development and interactive codebase analysis.

### Neovim (LazyVim IDE)
Neovim is configured as a full IDE using the **LazyVim** framework, featuring:
*   **Fuzzy Finder:** `Leader + Space` for instant file finding (LazyVim's current default picker is `snacks.picker`, not Telescope — Telescope is not installed).
*   **File Explorer:** `Leader + e` for an integrated file tree (`snacks.explorer`; Neo-tree is not installed).
*   **Language Servers:** All LSPs, formatters, and linters (Rust, Zig, Python, Nix, Lua, etc.) are installed declaratively via Nix in `home.nix` and picked up straight off `PATH`. Mason is deliberately disabled, so editor tooling stays reproducible with `nixos-rebuild` instead of drifting from whatever Mason downloaded at runtime. To add language support, add the package in `home.nix`. The plugins themselves are *not* Nix-managed: first launch clones lazy.nvim and every plugin pinned in `lazy-lock.json` from GitHub, and nvim-treesitter downloads and compiles its parsers. `:Lazy update` writes the new pins straight into this repo's `lazy-lock.json`, so updates show up in `git status` to commit or revert.
*   **Treesitter:** Automated syntax highlighting and structural editing.
*   **Start Screen:** a block-letter NIXOS header in the desktop's blue→green gradient.
*   **Colorscheme:** tokyonight's Night variant (LazyVim defaults to Moon), with a transparent background so Ghostty's blur shows through.
*   **Markdown:** rendered in the buffer by `render-markdown.nvim`. The browser-preview plugin from LazyVim's markdown extra is disabled (see `docs/gotchas.md`).

---

## ❄️ Fresh Installation Guide

To deploy this configuration to a brand-new machine:

`<host>` below is the `hosts/` directory name, i.e. the flake attribute — not necessarily the machine's hostname (`utm-vm`'s hostname is `utm-nixos`). A machine with no `hosts/` entry yet needs one first: see "Add a new host" in `CLAUDE.md`.

1.  **WiFi Setup:**
    ```bash
    nmcli device wifi connect "SSID" password "PASS"
    ```
2.  **Clone & Prepare:** the installer leaves its own generated config in `/etc/nixos`, and `git clone` refuses a non-empty target, so move it aside first. git isn't installed until the first switch, so borrow it from a `nix-shell`.
    ```bash
    sudo mv /etc/nixos /etc/nixos.installer
    sudo mkdir /etc/nixos && sudo chown $USER:users /etc/nixos
    nix-shell -p git
    git clone https://github.com/tewindavis/NixOSConfigs.git /etc/nixos
    cd /etc/nixos
    ```
3.  **Hardware Config:** (still inside the `nix-shell`; the flake only sees files git tracks, hence the `git add`)
    ```bash
    sudo nixos-generate-config --show-hardware-config > hosts/<host>/hardware-configuration.nix
    git add .
    ```
4.  **Install:** flakes aren't enabled on a fresh install until this config is applied (`modules/core` turns them on), so enable them for this one command.
    ```bash
    sudo nixos-rebuild switch --flake .#<host> --option experimental-features 'nix-command flakes'
    ```

*Note: Home Manager runs as a NixOS module, so all personal dotfiles and "rice" settings are applied by that same switch.*
