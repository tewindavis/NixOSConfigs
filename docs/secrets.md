# Secrets (sops-nix)

Wiring: `modules/core/secrets.nix` (imported by every host via
`modules/core/default.nix`). Encrypted file: `secrets/secrets.yaml`.
Recipients: `.sops.yaml`.

## Current state

Wiring is live but **inert** — no `sops.secrets.*` are declared anywhere
yet, so nothing actually gets decrypted at activation on any host. Only
`framework` is enrolled as an age recipient in `.sops.yaml`.

Each host decrypts using its own SSH host key
(`/etc/ssh/ssh_host_ed25519_key`), converted to an age key — not a
separately managed keypair. NixOS already provisions and protects that key,
so this avoids a second secret-management problem just to bootstrap the
first one.

## Running sops

`sops` isn't installed, and there is no personal age key: the only thing
that can decrypt is a recipient host's SSH host key, which only root can
read. So every `sops` command below runs like this, with `sudo` only reading
the key and `sops` itself running as you (your `$EDITOR`, file stays yours):

```bash
cd /etc/nixos
export SOPS_AGE_KEY=$(sudo nix run nixpkgs#ssh-to-age -- -private-key -i /etc/ssh/ssh_host_ed25519_key)
nix run nixpkgs#sops -- secrets/secrets.yaml      # or: -- updatekeys secrets/secrets.yaml
unset SOPS_AGE_KEY
```

To check which host a recipient line belongs to — no root needed, since this
is the *public* half:

```bash
nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
```

The output is the `age1…` string that host must appear as in `.sops.yaml`.
(Confirmed for `framework`: it matches the recipient recorded there.)

The key has to be *converted* (`ssh-to-age -private-key`), the same way
sops-nix does at activation, because the recipients in `.sops.yaml` are
`ssh-to-age` conversions. Pointing sops at the raw SSH key
(`SOPS_AGE_SSH_PRIVATE_KEY_FILE`) only works for files encrypted to
`ssh-ed25519` recipients, and fails here with "Failed to get the data key".
`unset` afterwards, since the variable holds the host's private key.

## Add a real secret

1. Confirm the target host is an age recipient in `.sops.yaml` (only
   `framework` is today — see "Enroll a new host" below if not).
2. `sops secrets/secrets.yaml` (run as in "Running sops" above) — opens
   cleartext in `$EDITOR`, re-encrypts automatically on save. Never
   hand-edit the encrypted file or commit a decrypted copy.
3. Declare it in the relevant module: `sops.secrets.my_secret = {};`
4. Reference the decrypted path at runtime:
   `config.sops.secrets.my_secret.path` (a runtime path under
   `/run/secrets/`, not the value itself — pass this path to whatever
   service/program needs the secret, don't try to read the value into Nix).

## Enroll a new host (e.g. dl-prototype, utm-vm)

```bash
# run ON the target host:
cat /etc/ssh/ssh_host_ed25519_key.pub | nix run nixpkgs#ssh-to-age
```

Add the resulting `age1...` key to `.sops.yaml` under `keys:`, add it to the
relevant `creation_rules` key group, then re-encrypt for the new recipient
(on a host that can already decrypt, i.e. framework, as in "Running sops"):

```bash
nix run nixpkgs#sops -- updatekeys secrets/secrets.yaml
```

Skipping `updatekeys` after a `.sops.yaml` change means the new host is
listed as a recipient but the file itself isn't actually re-encrypted for
it — decryption will fail on that host until this step runs.

## Safety notes

- Never commit an unencrypted `secrets/secrets.yaml` — the repo's
  `.gitignore` guards common secret-shaped filenames, but always diff before
  committing anything under `secrets/`.
- Don't add `sops.secrets.*` for a host that isn't yet a `.sops.yaml`
  recipient — activation will fail trying to decrypt with a key that can't.
