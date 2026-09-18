#!/usr/bin/env bash
# Fails if flake.lock pins more than one nixpkgs.
#
# Every input is meant to follow the root nixpkgs (`inputs.nixpkgs.follows`
# in flake.nix). An input that doesn't brings in its own, usually older,
# nixpkgs, which runs at build time and can put a second, unpatched copy of a
# package into the closure. The ghostty and nixos-hardware inputs once pinned
# two extra copies this way, one of them 8 months stale. Run from the repo
# root, or let `nix flake check` do it (see checks.single-nixpkgs in
# flake.nix).
#
# Nodes are matched by what they lock, not by their name, so a copy named
# something other than `nixpkgs_2` is still caught: a GitHub `nixpkgs` repo,
# or a channel tarball (`nixexprs.tar.*`).
set -euo pipefail

lock="${1:-flake.lock}"

mapfile -t copies < <(jq -r '
	.nodes | to_entries[]
	| select(
		((.value.locked.repo // "") | ascii_downcase) == "nixpkgs"
		or ((.value.locked.url // "") | test("nixexprs"))
	)
	| .key
' "$lock")

if [ "${#copies[@]}" -eq 1 ]; then
	exit 0
fi

echo "flake.lock pins ${#copies[@]} nixpkgs, expected exactly 1:" >&2
for node in "${copies[@]}"; do
	# Name the input(s) that pull this copy in, so the fix is obvious.
	users=$(jq -r --arg n "$node" '
		.nodes | to_entries[]
		| select(.value.inputs? and (.value.inputs | to_entries | any(.value == $n)))
		| .key
	' "$lock" | paste -sd, -)
	echo "  $node (used by: ${users:-none})" >&2
done
echo "Add \`inputs.nixpkgs.follows = \"nixpkgs\";\` to those inputs in flake.nix." >&2
exit 1
