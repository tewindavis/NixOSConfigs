{ pkgs, ... }:

{
  # Binary Analysis Toolkit
  environment.systemPackages = with pkgs; [
    ghidra
    radare2
    gdb
    pwndbg
    binutils
    file
    ltrace
    strace
  ];

  # RL Development Environment (CPU focused)
  # We use a system-wide python with essential RL libs
  # Note: For serious work, a nix-shell or devenv is preferred
  users.users.td.packages = with pkgs; [
    (python3.withPackages (ps: with ps; [
      torch
      numpy
      stable-baselines3
      gymnasium
    ]))
  ];
}
