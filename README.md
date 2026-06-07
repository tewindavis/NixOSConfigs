# NixOS Configurations: Multi-System Architecture

This repository contains a modular NixOS configuration managed via Flakes, designed to support three distinct hardware profiles sharing a common core and user experience.

## 🖥️ Target Systems

### 1. UTM Virtual Machine (`utm-vm`)
*   **Architecture:** `aarch64-linux` (MacOS Apple Silicon)
*   **Role:** Development sandbox on MacOS.
*   **Hardware Profile:** Optimized for VirtIO graphics and Spice guest services (clipboard sharing, resolution scaling).

### 2. Framework 13 (`framework`)
*   **Architecture:** `x86_64-linux`
*   **Role:** Primary portable workstation.
*   **Hardware Profile:** Integrated with `nixos-hardware` for platform-specific optimizations (power management, touchpad support).

### 3. Training Rig (`dl-prototype`)
*   **Architecture:** `x86_64-linux` (AMD Threadripper + NVIDIA)
*   **Role:** Reinforcement Learning (RL) training and Binary Analysis.
*   **Hardware Profile:** High-performance CPU governor, NVIDIA proprietary drivers, and AMD microcode updates.

---

## 🏗️ Design Choices

### 1. Modular Extraction
Hardware-specific logic is isolated in `modules/hardware/`. This prevents "leakage" (e.g., VM guest services trying to start on physical hardware) and allows for a clean `imports` list in each host configuration.

### 2. Unified User Management
User configurations are split into two layers:
*   **System Layer (`users/td/nixos.nix`):** Handles UID, groups (`wheel`, `networkmanager`), and system-level shell.
*   **User Layer (`users/td/home.nix`):** Managed via **Home Manager**, handling dotfiles, personal packages, and environment variables.

### 3. Desktop Environment via Home Manager
Window manager settings (Hyprland keybindings, UI components like Waybar/Wofi) are managed at the user level in `users/td/home.nix`. This makes the desktop environment more portable and decoupled from system-level hardware configurations.

### 4. Specialized Dev Profiles
The `modules/dev/` directory contains task-specific configurations. For example, `rl-binary.nix` bundles a complete toolkit for low-level research:
*   **Binary Analysis:** Ghidra, Radare2, GDB/Pwndbg.
*   **RL Stack:** Python 3 environment with PyTorch and Stable Baselines 3.

---

## 🛠️ Key Functionalities Installed

*   **Desktop:** Hyprland (Wayland) with a survival kit including Ghostty (riced/transparent), Waybar, Wofi, Dunst, and Thunar.
*   **Editor:** Neovim with **LazyVim** framework.
    *   **Features:** Automated LSP management, syntax highlighting (Treesitter), and IDE-like UI.
    *   **Bundled LSPs:** `rust-analyzer` (Rust), `zls` (Zig), `nil` (Nix), `pyright`/`ruff` (Python), and more.
*   **Languages & Toolchains:**
    *   **Rust:** `rustup` and `rustlings` for learning.
    *   **Zig:** `zig` compiler and `zls` (Language Server).
    *   **Lua:** `lua` interpreter and `lua-language-server`.
    *   **Julia:** `julia` programming language.
    *   **C/C++:** `gcc`, `gnumake`, `cmake`, and `gdb`.
    *   **Python:** Python 3 with `pip`, `virtualenv`, and formatting tools (`black`, `isort`).
*   **Modern CLI:** `gemini-cli` (AI Agent), `starship` (custom prompt), `ripgrep`, `fd`, `bat`, `eza`, `zoxide`, `fzf`, and `bottom`.
*   **Workflow:** `direnv` with `nix-direnv` for automatic, zero-latency flake environment loading.
*   **Core Tools:** Git, Vim, Tmux, Htop, Curl, Wget.
*   **Security:** Mullvad VPN (daemon + GUI), Proton VPN (CLI + GUI), SSH Agent enabled by default.
*   **Networking:** `systemd-resolved` for reliable DNS with VPN switching.
*   **Hardware:** Bluetooth enabled with `blueman` manager (Framework & DL).
*   **Aesthetics:** Nerd Fonts (Fira Code, JetBrains Mono) and Emoji support.

---

## 🚀 Usage

To build a configuration:

```bash
# Example for the Framework
sudo nixos-rebuild switch --flake .#framework
```

---

## ❄️ Fresh Installation Guide

If you are installing this configuration on a brand-new machine:

1.  **Boot the NixOS Installer:**
    Follow the standard [NixOS installation guide](https://nixos.org/manual/nixos/stable/index.html#sec-installation) to partition and mount your drives under `/mnt`.

2.  **Clone this Repository:**
    ```bash
    git clone https://github.com/tewindavis/NixOSConfigs.git /mnt/etc/nixos
    cd /mnt/etc/nixos
    git checkout vibes
    ```

3.  **Generate Hardware Configuration:**
    This step is critical to ensure your specific disk UUIDs and kernel modules are captured.
    ```bash
    # Ensure you are in the correct host directory (e.g., framework)
    sudo nixos-generate-config --root /mnt --show-hardware-config > hosts/framework/hardware-configuration.nix
    ```

4.  **Install the System:**
    ```bash
    sudo nixos-install --flake .#framework
    ```

5.  **Reboot & Finalize:**
    Reboot into your new system. Once logged in, the `home-manager` profile will automatically apply your desktop settings, terminal rice, and dev tools.

*Note: For the Threadripper rig (`dl-prototype`), remember to verify your NVIDIA driver version in `modules/hardware/nvidia.nix` if the card is older than the GTX 900 series.*
