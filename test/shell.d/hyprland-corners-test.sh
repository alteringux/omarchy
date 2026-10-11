#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

stub_dir="$tmpdir/bin"
home_dir="$tmpdir/home"
toggles_dir="$home_dir/.local/state/omarchy/toggles/hypr"
mkdir -p "$stub_dir" "$home_dir"

for command in hyprctl omarchy-notification-send; do
  printf '#!/bin/bash\nprintf "%%s\\n" "%s $*" >>"%s/commands.log"\n' "$command" "$tmpdir" >"$stub_dir/$command"
done
chmod +x "$stub_dir"/*

run() {
  HOME="$home_dir" XDG_STATE_HOME="$home_dir/.local/state" OMARCHY_PATH="$ROOT" PATH="$stub_dir:$ROOT/bin:$PATH" "$@"
}

[[ $(run omarchy-hyprland-corners) == "theme" ]] || fail "corners start out following the theme"
pass "corners start out following the theme"

run omarchy-hyprland-corners rounded
[[ $(run omarchy-hyprland-corners) == "rounded" ]] || fail "rounded corners are reported"
cmp -s "$ROOT/default/hypr/toggles/corners-rounded.lua" "$toggles_dir/corners-rounded.lua" || fail "rounded corners are loaded after the theme"
grep -qx 'hyprctl reload' "$tmpdir/commands.log" || fail "new corners reload Hyprland"
pass "rounded corners override the theme"

run omarchy-hyprland-corners sharp
[[ $(run omarchy-hyprland-corners) == "sharp" ]] || fail "sharp corners are reported"
[[ ! -e $toggles_dir/corners-rounded.lua ]] || fail "sharp corners replace rounded ones"
pass "sharp corners replace rounded ones"

run omarchy-hyprland-corners theme
[[ $(run omarchy-hyprland-corners) == "theme" ]] || fail "theme corners are reported"
[[ ! -e $toggles_dir/corners-sharp.lua ]] || fail "theme corners drop the override"
pass "theme corners drop the override"

if run omarchy-hyprland-corners square 2>/dev/null; then
  fail "unknown corners are refused"
fi
pass "unknown corners are refused"

# Hyprland loads toggles from XDG_STATE_HOME, so the corners have to land there.
state_home="$tmpdir/state"
HOME="$home_dir" XDG_STATE_HOME="$state_home" OMARCHY_PATH="$ROOT" PATH="$stub_dir:$ROOT/bin:$PATH" omarchy-hyprland-corners sharp
[[ -f $state_home/omarchy/toggles/hypr/corners-sharp.lua ]] || fail "corners follow XDG_STATE_HOME"
[[ $(HOME="$home_dir" XDG_STATE_HOME="$state_home" PATH="$ROOT/bin:$PATH" omarchy-hyprland-corners) == "sharp" ]] || fail "corners are read from XDG_STATE_HOME"
pass "corners follow XDG_STATE_HOME"

# Rounded corners are Solitude's, so the two must not drift apart.
[[ $(grep -E '^\s*rounding(_power)? =' "$ROOT/default/hypr/toggles/corners-rounded.lua") == "$(grep -E '^\s*rounding(_power)? =' "$ROOT/themes/solitude/hyprland.lua")" ]] ||
  fail "rounded corners match Solitude's"
pass "rounded corners match Solitude's"
