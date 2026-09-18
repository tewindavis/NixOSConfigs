# NixOS Golden State: Multi-System Architecture
**Architect & Implementer:** Google Gemini (2026)
**Contributor:** Claude Code (Sonnet 5, 2026)

This repository contains a professional-grade, highly modular NixOS configuration managed via Flakes. It is designed to provide a unified "Golden State" developer experience across three distinct hardware profiles, featuring a high-saturation "riced" desktop and a pre-equipped toolkit for modern engineering.

---

## 🖥️ Target Architectures

The system uses a modular extraction pattern (`modules/hardware/`) to isolate host-specific logic, ensuring that software configurations remain pure and portable.

*   **`utm-vm`:** Aarch64 sandbox optimized for MacOS/Apple Silicon. Features VirtIO graphics and Spice guest integration.
*   **`framework`:** Primary x86_64 portable workstation. Optimized for Framework 13 hardware, including HiDPI scaling (1.175), fingerprint authentication (`fprintd`, wired into login/sudo/hyprlock), and automatic firmware updates (`fwupd`).
*   **`dl-prototype`:** High-performance x86_64 training rig. Configured for AMD Threadripper CPU optimization and NVIDIA proprietary driver support.

---

## 🎨 The "Tokyo Night" Aesthetic

The desktop environment is built on the **Tokyo Night (Night)** color palette, optimized for high contrast and vibrant visual energy without pastel washout.

*   **Vibrant Glass:** All windows feature a "True Glass" aesthetic (90% active / 80% inactive opacity) with absolute minimum blur (1/1) for maximum clarity.
*   **Complementary Spectrum:** Status modules and UI accents use a bold spectrum: **Blue** (#7aa2f7) for identity, **Green** (#9ece6a) for location, and **Orange** (#ff9e64) for status.
*   **Automated Art:** The `setup-wallpapers` script fetches a starter Hyprchan wallpaper into `~/Pictures/Wallpapers` on first boot; drop in more images and `cycle-wallpaper` (`SUPER + W`) will pick a random one from the folder each time.
*   **Themed Lock & Notifications:** `hyprlock` (with a live clock, date, and Fingerprint-or-Password prompt), `dunst`, the `swayosd` volume/brightness OSD, and the `wlogout` power menu are all styled to match the Waybar/Wofi palette — dark translucent panels, blue borders, and urgency-tiered accent colors, including a recolored `wlogout` icon set (blue lock/logout, green suspend/hibernate, orange reboot, red shutdown).
*   **Idle Inhibitor:** A clickable Waybar toggle (right of the volume module) suspends `hypridle`'s auto-lock/DPMS while active — turns red when suppressing.
*   **Persistent Workspaces:** Waybar always shows workspaces 1-9, even when empty, so the active one is never ambiguous.
*   **Weather:** A Waybar module next to the clock shows current conditions via `wttr.in`, with a graceful "N/A" fallback if the network or upstream service is unavailable.
*   **Auto Blue-Light Filter:** `hyprsunset` runs as a daemon on login and switches itself between neutral (7:30am) and warm 2450K (8:00pm) — f.lux/redshift-style — per the schedule in `hyprsunset.conf`. A Waybar toggle (sun/moon icon, next to the idle inhibitor) shows and flips the current state; `SUPER + R`/`SUPER + SHIFT + R` do the same from the keyboard. Any of the three count as a manual override until the next scheduled switch.

---

## ⌨️ Hyprland Cheat Sheet

All system controls are bound to the **`SUPER`** (Command) key.

### Applications & Navigation
| Key | Action |
|:--- |:---|
| `SUPER + T` or `SUPER + Return` | Open Ghostty Terminal |
| `SUPER + Space` | Launch Application Menu (Wofi) |
| `SUPER + E` | Open File Manager (Thunar) |
| `SUPER + X` | Kill Active Window |
| `SUPER + H/J/K/L` | Move Focus (Vim-style) |
| `SUPER + 1-9` | Switch Workspace |
| `SUPER + SHIFT + 1-9` | Move Window to Workspace |
| `SUPER + F` | Toggle Fullscreen |
| `SUPER + P` | Toggle Pseudotile |
| `SUPER + SHIFT + Space` | Toggle Floating |
| `SUPER + S` | Toggle Dropdown Scratchpad Terminal |
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
| `SUPER + N` | Pop Last Dismissed Notification |
| `SUPER + SHIFT + P` | Power Menu |
| `SUPER + W` | Cycle Wallpaper |
| `SUPER + SHIFT + W` | Toggle Blackout Wallpaper (solid black, for glare relief) |
| `SUPER + R` | Manual Override: Aggressive Hyprsunset (2500K) |
| `SUPER + SHIFT + R` | Manual Override: Reset Hyprsunset (Day Mode) |
| `SUPER + Left Click` | **Drag to Move** Window |
| `SUPER + Right Click`| **Drag to Resize** Window |
| `Media Keys` | Volume, Mic, and Brightness Control (with on-screen display) |

---

## 🛠️ The Developer Toolkit

The environment is "ready-to-code" immediately upon login, featuring a modern Zsh shell and a full compiler stack.

*   **Languages:** Rust (Cargo/Rustc/Rustlings), Zig (ZLS), Julia, Lua, Octave, C/C++, and Python 3.
*   **Modern Shell:** Zsh is the default shell, featuring syntax highlighting, auto-suggestions, and the **Starship** Powerline prompt.
*   **CLI Essentials:** `ripgrep`, `fd`, `bat` (cat), `eza` (ls), `zoxide` (cd), `gh` (GitHub CLI), and `direnv` for automatic flake environment loading.
*   **Media & Printing:** `mpv` handles video/audio opened from Thunar; CUPS + Avahi provide zero-config discovery and printing to network/AirPrint printers, managed via `system-config-printer`.
*   **Screen Sharing:** `xdg-desktop-portal-hyprland` is wired in alongside the GTK portal, so screen/window capture works in Brave, Discord, OBS, etc.
*   **Screen Recording:** `SUPER + ALT + R` toggles `wf-recorder` in the background, saving timestamped mp4s to `~/Videos/Recordings` with a dunst start/stop notification.
*   **Archives:** `xarchiver` (Thunar's archive-plugin backend) plus `p7zip`/`unrar`/`zip`/`unzip` handle zip/7z/rar/tar/gzip out of the box.
*   **Password Manager:** `keepassxc` is the default handler for `.kdbx` files.
*   **File Sync:** `syncthing` runs as a system service (LAN/P2P sync), with `syncthingtray` in the waybar tray for status/control; `rclone` is available for cloud-storage remotes.
*   **System Monitor:** `resources`, a GTK4/libadwaita system monitor, complements the CLI `htop`/`bottom`.
*   **Firmware:** `gnome-firmware` gives a GUI alongside `fwupdmgr` for firmware updates.
*   **AI Integration:** `claude-code` and `antigravity-cli` are pre-installed for agentic development and interactive codebase analysis.

### Neovim (LazyVim IDE)
Neovim is configured as a full IDE using the **LazyVim** framework, featuring:
*   **Fuzzy Finder:** `Leader + Space` for instant file finding (LazyVim's current default picker is `snacks.picker`, not Telescope — Telescope is not installed).
*   **File Explorer:** `Leader + e` for an integrated file tree (`snacks.explorer`; Neo-tree is not installed).
*   **Language Servers:** All LSPs, formatters, and linters (Rust, Zig, Python, Nix, Lua, etc.) are installed declaratively via Nix in `home.nix` and picked up straight off `PATH`. Mason is deliberately disabled, so editor tooling stays reproducible with `nixos-rebuild` instead of drifting from whatever Mason downloaded at runtime — nothing is fetched on first launch. To add language support, add the package in `home.nix`.
*   **Treesitter:** Automated syntax highlighting and structural editing.

---

## ❄️ Fresh Installation Guide

To deploy this configuration to a brand-new machine:

1.  **WiFi Setup:**
    ```bash
    nmcli device wifi connect "SSID" password "PASS"
    ```
2.  **Clone & Prepare:**
    ```bash
    sudo chown -R $USER:users /etc/nixos
    git clone git@github.com:tewindavis/NixOSConfigs.git /etc/nixos
    cd /etc/nixos
    ```
3.  **Hardware Config:**
    ```bash
    sudo nixos-generate-config --show-hardware-config > hosts/<hostname>/hardware-configuration.nix
    git add .
    ```
4.  **Install:**
    ```bash
    sudo nixos-rebuild switch --flake .#<hostname>
    ```

*Note: All personal dotfiles and "rice" settings are managed via Home Manager and will activate automatically upon login.*
