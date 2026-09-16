# NixOS Golden State: Multi-System Architecture
**Architect & Implementer:** Google Gemini (2026)
**Contributor:** Claude Code (Sonnet 5, 2026)

This repository contains a professional-grade, highly modular NixOS configuration managed via Flakes. It is designed to provide a unified "Golden State" developer experience across three distinct hardware profiles, featuring a high-saturation "riced" desktop and a pre-equipped toolkit for modern engineering.

---

## 🖥️ Target Architectures

The system uses a modular extraction pattern (`modules/hardware/`) to isolate host-specific logic, ensuring that software configurations remain pure and portable.

*   **`utm-vm`:** Aarch64 sandbox optimized for MacOS/Apple Silicon. Features VirtIO graphics and Spice guest integration.
*   **`framework`:** Primary x86_64 portable workstation. Optimized for Framework 13 hardware, including HiDPI scaling (1.17), fingerprint authentication (`fprintd`, wired into login/sudo/hyprlock), and automatic firmware updates (`fwupd`).
*   **`dl-prototype`:** High-performance x86_64 training rig. Configured for AMD Threadripper CPU optimization and NVIDIA proprietary driver support.

---

## 🎨 The "Tokyo Night" Aesthetic

The desktop environment is built on the **Tokyo Night (Night)** color palette, optimized for high contrast and vibrant visual energy without pastel washout.

*   **Vibrant Glass:** All windows feature a "True Glass" aesthetic (90% active / 80% inactive opacity) with absolute minimum blur (1/1) for maximum clarity.
*   **Complementary Spectrum:** Status modules and UI accents use a bold spectrum: **Blue** (#7aa2f7) for identity, **Green** (#9ece6a) for location, and **Orange** (#ff9e64) for status.
*   **Automated Art:** The `setup-wallpapers` script fetches a starter Hyprchan wallpaper into `~/Pictures/Wallpapers` on first boot; drop in more images and `cycle-wallpaper` (`SUPER + W`) will pick a random one from the folder each time.
*   **Themed Lock & Notifications:** `hyprlock` (with a live clock, date, and Fingerprint-or-Password prompt) and `dunst` are styled to match the Waybar/Wofi palette — dark translucent panels, blue borders, and urgency-tiered accent colors.

---

## ⌨️ Hyprland Cheat Sheet

All system controls are bound to the **`SUPER`** (Command) key.

### Applications & Navigation
| Key | Action |
|:--- |:---|
| `SUPER + T` | Open Ghostty Terminal |
| `SUPER + Space` | Launch Application Menu (Wofi) |
| `SUPER + E` | Open File Manager (Thunar) |
| `SUPER + X` | Kill Active Window |
| `SUPER + H/J/K/L` | Move Focus (Vim-style) |
| `SUPER + 1-9` | Switch Workspace |
| `SUPER + SHIFT + 1-9` | Move Window to Workspace |
| `SUPER + SHIFT + E` | Exit Hyprland |
| `3-Finger Swipe` | Switch Workspace (Gesture) |

### System & Hardware
| Key | Action |
|:--- |:---|
| `SUPER + SHIFT + L` | Lock Screen (Heavy Blur) |
| `SUPER + W` | Cycle Wallpaper |
| `SUPER + R` | Aggressive Hyprsunset (2500K) |
| `SUPER + SHIFT + R` | Reset Hyprsunset (Day Mode) |
| `SUPER + Left Click` | **Drag to Move** Window |
| `SUPER + Right Click`| **Drag to Resize** Window |
| `Media Keys` | Volume, Mic, and Brightness Control |

---

## 🛠️ The Developer Toolkit

The environment is "ready-to-code" immediately upon login, featuring a modern Zsh shell and a full compiler stack.

*   **Languages:** Rust (Cargo/Rustc/Rustlings), Zig (ZLS), Julia, Lua, Octave, C/C++, and Python 3.
*   **Modern Shell:** Zsh is the default shell, featuring syntax highlighting, auto-suggestions, and the **Starship** Powerline prompt.
*   **CLI Essentials:** `ripgrep`, `fd`, `bat` (cat), `eza` (ls), `zoxide` (cd), `gh` (GitHub CLI), and `direnv` for automatic flake environment loading.
*   **AI Integration:** `claude-code` and `antigravity-cli` are pre-installed for agentic development and interactive codebase analysis.

### Neovim (LazyVim IDE)
Neovim is configured as a full IDE using the **LazyVim** framework, featuring:
*   **Telescope:** `Leader + Space` for instant fuzzy finding.
*   **Neo-tree:** `Leader + e` for an integrated file explorer.
*   **Language Servers:** LazyVim's Mason auto-installs LSPs on first launch for your installed languages (Rust, Zig, Python, Nix, etc.) — requires internet access the first time it runs.
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
