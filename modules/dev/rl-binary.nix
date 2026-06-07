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
  # Global profile already handles numpy/torch/ipython
  users.users.td.packages = with pkgs; [
    (python3.withPackages (ps: with ps; [
      stable-baselines3
      gymnasium
      scikit-learn
    ]))
  ];
}
