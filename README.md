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

### 3. Specialized Dev Profiles
The `modules/dev/` directory contains task-specific configurations. For example, `rl-binary.nix` bundles a complete toolkit for low-level research:
*   **Binary Analysis:** Ghidra, Radare2, GDB/Pwndbg.
*   **RL Stack:** Python 3 environment with PyTorch and Stable Baselines 3.

---

## 🛠️ Key Functionalities Installed

*   **Desktop:** Hyprland (Wayland) with a survival kit including Ghostty, Waybar, Wofi, and Dunst.
*   **Editor:** Neovim with **LazyVim** framework.
    *   **Features:** Automated LSP management, syntax highlighting (Treesitter), and IDE-like UI.
    *   **Bundled LSPs:** `rust-analyzer` (Rust), `zls` (Zig), `nil` (Nix), `pyright`/`ruff` (Python), and more.
*   **Languages & Toolchains:**
    *   **Rust:** `rustup` and `rustlings` for learning.
    *   **Zig:** `zig` compiler and `zls` (Language Server).
    *   **C/C++:** `gcc`, `gnumake`, `cmake`, and `gdb`.
    *   **Python:** Python 3 with `pip`, `virtualenv`, and formatting tools (`black`, `isort`).
*   **Modern CLI:** `ripgrep`, `fd`, `bat`, `eza`, `zoxide`, `fzf`, and `bottom`.
*   **Workflow:** `direnv` with `nix-direnv` for automatic, zero-latency flake environment loading.
*   **Core Tools:** Git, Vim, Tmux, Htop, Curl, Wget.
*   **Security:** SSH Agent enabled by default, OpenSSH for remote management.
*   **Aesthetics:** Nerd Fonts (Fira Code, JetBrains Mono) and Emoji support.

---

## 🚀 Usage

To build a configuration:

```bash
# Example for the Framework
sudo nixos-rebuild switch --flake .#framework
```

*Note: For new physical installs, ensure you generate and include a valid `hardware-configuration.nix` for the specific machine.*
