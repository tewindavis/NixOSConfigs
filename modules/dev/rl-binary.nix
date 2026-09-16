{ pkgs, ... }:

{
  # Binary Analysis Toolkit
  environment.systemPackages = with pkgs; [
    ghidra
    radare2
    gdb
    # pwndbg was never an actual nixpkgs package (it ships its own
    # setup.sh/venv installer upstream); gef is the nixpkgs-packaged
    # equivalent for the same pwn/CTF GDB-enhancement use case.
    gef
    binutils
    file
    ltrace
    strace
  ];

  # RL Development Environment (CPU focused)
  # Global profile already handles numpy/torch/ipython
  users.users.td.packages = with pkgs; [
    (python3.withPackages (
      ps:
      let
        # doCheck disabled: gymnasium's own nativeCheckInputs pull in
        # flax -> keras -> tf-keras -> tensorflow, and tensorflow is marked
        # broken in this nixpkgs pin. Patched here (not just added as a
        # sibling package below) because stable-baselines3 already built
        # against the *unpatched* gymnasium via its propagatedBuildInputs --
        # a sibling override wouldn't retroactively fix that reference.
        patchedGymnasium = ps.gymnasium.overridePythonAttrs { doCheck = false; };
      in
      [
        # doCheck disabled here too: stable-baselines3's own
        # nativeCheckInputs separately pull in tensorboard -> tensorflow.
        ((ps.stable-baselines3.override { gymnasium = patchedGymnasium; }).overridePythonAttrs {
          doCheck = false;
        })
        patchedGymnasium
        ps.scikit-learn
      ]
    ))
  ];
}
