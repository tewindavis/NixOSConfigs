{ ... }:

{
  # sops-nix: encrypted secrets, decrypted at activation using each host's own
  # SSH host key (converted to an age key — see .sops.yaml at the repo root
  # for how recipients are managed). Nothing is actually declared here yet
  # (no `sops.secrets.*`), so this is inert wiring: it doesn't try to decrypt
  # anything at activation, and won't break a host that isn't yet enrolled as
  # a recipient in .sops.yaml.
  #
  # To add a real secret:
  #   1. Make sure this host's key is a recipient in .sops.yaml (framework's
  #      already is).
  #   2. sops secrets/secrets.yaml   # edit in cleartext, re-encrypts on save
  #   3. Declare it: sops.secrets.my_secret = {};
  #      then reference its decrypted path: config.sops.secrets.my_secret.path
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
