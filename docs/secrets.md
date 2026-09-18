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

## Add a real secret

1. Confirm the target host is an age recipient in `.sops.yaml` (only
   `framework` is today — see "Enroll a new host" below if not).
2. `sops secrets/secrets.yaml` — opens cleartext in `$EDITOR`,
   re-encrypts automatically on save. Never hand-edit the encrypted file or
   commit a decrypted copy.
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
relevant `creation_rules` key group, then re-encrypt for the new recipient:

```bash
sops updatekeys secrets/secrets.yaml
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
