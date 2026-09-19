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
        stableBaselines3 =
          (ps.stable-baselines3.override { gymnasium = patchedGymnasium; }).overridePythonAttrs
            {
              doCheck = false;
            };
        # PrometheusCallback for model.learn(): exports everything SB3 logs
        # to 127.0.0.1:9435, scraped by training-metrics.nix. Usage is in
        # the module's docstring.
        sb3Prometheus = ps.buildPythonPackage {
          pname = "sb3-prometheus";
          version = "0.1.0";
          pyproject = true;
          src = ./sb3_prometheus;
          build-system = [ ps.setuptools ];
          dependencies = [
            ps.prometheus-client
            stableBaselines3
          ];
          pythonImportsCheck = [ "sb3_prometheus" ];
        };
      in
      [
        # doCheck disabled here too (in stableBaselines3 above):
        # stable-baselines3's own nativeCheckInputs separately pull in
        # tensorboard -> tensorflow.
        stableBaselines3
        patchedGymnasium
        sb3Prometheus
        ps.prometheus-client
        ps.scikit-learn
      ]
    ))
  ];
}
