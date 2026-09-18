# Documentation maintenance

Rules for changing `README.md`, `CLAUDE.md`, or anything in `docs/`.

Written after an audit of these very files found five stale claims in README,
three of which were actively wrong: it advertised Mason, Telescope and
Neo-tree, none of which are installed. Every rule below is a mistake that
actually happened here, not hypothetical hygiene.

## Source-of-truth map

Docs restate what the code already says. When a doc and its authority
disagree, **the authority wins and the doc is the bug** — fix the doc, don't
bend the code to match it.

| Question | Authority |
|---|---|
| Which keys are bound | `users/td/hypr/hyprland.lua` |
| Which packages, LSPs, scripts, dotfiles exist | `users/td/home.nix` |
| Which modules a host gets | `hosts/<name>/configuration.nix` |
| Which Neovim plugins are installed | `users/td/nvim/lazy-lock.json` |
| Which hosts can decrypt secrets | `.sops.yaml` |
| Which ports each host opens | evaluated `networking.firewall` (command in `docs/security.md`) |
| Formatting/lint rules | `treefmt.nix` |
| Waybar modules and click actions | `users/td/waybar/config.jsonc` |

## Rules

**1. Verify each claim against the source before writing it.** Open the file.
If a claim names a plugin, package, or option, grep for it — `lazy-lock.json`
is how the Telescope and Neo-tree claims were caught, and they had been wrong
for a long time. A plausible-sounding claim inherited from an older doc is
exactly the kind that survives unchecked.

**2. Never describe another document's state.** Sentences like "README is
accurate" or "README's cheat sheet is incomplete" rot the moment someone acts
on them, and they did — twice in one session. Fixing README made two
correct-at-the-time warnings about README wrong. Point at the authority and
give the command to regenerate instead:

> `hyprland.lua` is the source of truth — regenerate with
> `grep 'hl.bind' users/td/hypr/hyprland.lua`.

That sentence stays true no matter what any doc says.

**3. Never defer to a doc you haven't read.** The first draft of these files
said "README's cheat sheet is accurate, no need to duplicate it." Nobody had
checked. It was missing four binds. Deferring is fine; deferring *unverified*
is how an error gets laundered into a second file.

**4. Prefer a mechanical check over a written reminder.** "Remember to update
the README" is a reminder nobody reads. `checks.keybindings` is a build
failure. If a doc fact can be diffed against its source, wire it into
`checks` in `flake.nix` — and confirm the check can actually *fail* before
trusting it (break the input on purpose; two real bugs in
`scripts/check-keybinds.sh` only surfaced that way).

**5. One fact, one home.** Duplicating a fact doubles the places it can go
stale. Each file has a job:

- `README.md` — human-facing tour: what exists, what it feels like, how to install.
- `CLAUDE.md` (root) — agent entry point. Always loaded, so keep it lean: layout, workflows, pointers.
- `docs/*.md` — deep reference, read on demand.

The keybind table is the one deliberate exception (README for humans,
`docs/desktop.md` for agents) — and that duplication is only tolerable
because a check enforces it.

## What is and isn't machine-checked

- **Checked:** README's keybind cheat sheet vs. `hyprland.lua`, via
  `checks.keybindings` / `scripts/check-keybinds.sh`, in both directions.
- **Not checked:** everything else — `docs/desktop.md`'s own keybind table,
  the host/module table in `docs/hosts.md`, package lists, palette values.
  These are hand-maintained; verify them by reading the source.

Run `nix flake check` after doc changes. It is cheap and catches the one
class of drift that is automated.

## When you change code, update docs in the same commit

| Change | Also update |
|---|---|
| Add/remove a keybind | `README.md` cheat sheet **and** `docs/desktop.md` (only the first is enforced) |
| Add/remove a module import | host table in `docs/hosts.md` |
| Add a package, script, or LSP | `users/td/home.nix` is authoritative; touch docs only if they enumerate it |
| Hit a non-obvious bug/constraint | `docs/gotchas.md`, and leave a comment at the code site |
| Enroll a sops recipient | `docs/secrets.md` |
| Open/close a port, or change SSH, PAM, boot or resolver hardening | `docs/security.md` |

Prefer recording hard-won knowledge as a comment at the code site *and* a
line in `docs/gotchas.md`: the comment survives refactors, the doc is
findable without knowing where to look.
