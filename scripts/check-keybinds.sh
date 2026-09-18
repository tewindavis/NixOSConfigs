#!/usr/bin/env bash
# Fails if README.md's Hyprland cheat sheet and hyprland.lua disagree about
# which keys are bound.
#
# hyprland.lua is the source of truth; this only reports drift, it never edits
# either file. Run it from the repo root, or let `nix flake check` do it (see
# checks.keybindings in flake.nix).
#
# Written because the cheat sheet silently drifted four binds out of date
# (SUPER+Return/C/N/SHIFT+W) before anyone noticed.
set -euo pipefail

lua="${1:-users/td/hypr/hyprland.lua}"
readme="${2:-README.md}"

# Both sides get uppercased and stripped of spaces around "+" so that
# `SUPER + h` and `SUPER+H` compare equal.
normalize() {
	tr '[:lower:]' '[:upper:]' |
		sed -E 's/[[:space:]]*\+[[:space:]]*/+/g; s/^[[:space:]]+//; s/[[:space:]]+$//' |
		grep -v '^$' | sort -u
}

binds_from_lua() {
	{
		# hl.bind(mainMod .. " + <combo>", ...)
		# The trailing comma is load-bearing: it anchors to the end of the key
		# argument, so the `.. i` loop forms below don't match here as well.
		grep -oE 'hl\.bind\(mainMod \.\. " \+ [^"]+",' "$lua" |
			sed -E 's/^.*\.\. " \+ //; s/",$//; s/^/SUPER+/'

		# hl.bind("<key>", ...) — bare keys: Print, XF86*
		grep -oE 'hl\.bind\("[^"]+"' "$lua" |
			sed -E 's/^hl\.bind\("//; s/"$//'

		# `for i = 1, 9` workspace loops, which bind 1-9 dynamically
		if grep -qE 'hl\.bind\(mainMod \.\. " \+ " \.\. i' "$lua"; then
			seq 1 9 | sed 's/^/SUPER+/'
		fi
		if grep -qE 'hl\.bind\(mainMod \.\. " \+ SHIFT \+ " \.\. i' "$lua"; then
			seq 1 9 | sed 's/^/SUPER+SHIFT+/'
		fi
	} | normalize
}

# The cheat sheet writes some binds as human shorthand covering several real
# binds at once. Expand those to the underlying keys so they can be compared.
expand_shorthand() {
	while IFS= read -r key; do
		case "$key" in
		*H/J/K/L*) printf 'SUPER+%s\n' H J K L ;;
		"SUPER + SHIFT + 1-9") seq 1 9 | sed 's/^/SUPER+SHIFT+/' ;;
		"SUPER + 1-9") seq 1 9 | sed 's/^/SUPER+/' ;;
		"Media Keys") printf '%s\n' \
			XF86AudioRaiseVolume XF86AudioLowerVolume \
			XF86AudioMute XF86AudioMicMute \
			XF86MonBrightnessUp XF86MonBrightnessDown ;;
		*"Left Click") echo "SUPER+mouse:272" ;;
		*"Right Click") echo "SUPER+mouse:273" ;;
		"3-Finger Swipe") ;; # hl.gesture, not a keybind
		*) echo "$key" ;;
		esac
	done
}

binds_from_readme() {
	# Only the cheat-sheet section, only table rows, only the first column —
	# the Action column contains backticked paths that aren't keys.
	awk '/Hyprland Cheat Sheet/{f=1; next} f && /^## /{f=0} f' "$readme" |
		grep '^|' |
		sed -E 's/^\|([^|]*)\|.*/\1/' |
		grep -oE '`[^`]+`' |
		tr -d '`' |
		expand_shorthand |
		normalize
}

for f in "$lua" "$readme"; do
	[ -r "$f" ] || {
		echo "check-keybinds: cannot read $f (run from the repo root?)" >&2
		exit 2
	}
done

undocumented=$(comm -23 <(binds_from_lua) <(binds_from_readme))
phantom=$(comm -13 <(binds_from_lua) <(binds_from_readme))

status=0
if [ -n "$undocumented" ]; then
	echo "Bound in $lua but missing from $readme's cheat sheet:" >&2
	echo "$undocumented" | sed 's/^/  /' >&2
	status=1
fi
if [ -n "$phantom" ]; then
	echo "Listed in $readme's cheat sheet but not bound in $lua:" >&2
	echo "$phantom" | sed 's/^/  /' >&2
	status=1
fi

if [ "$status" -eq 0 ]; then
	echo "check-keybinds: README cheat sheet matches hyprland.lua"
else
	echo "" >&2
	echo "hyprland.lua is the source of truth — update the README to match." >&2
fi
exit "$status"
