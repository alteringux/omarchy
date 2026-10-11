#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

stub_dir="$tmpdir/bin"
home_dir="$tmpdir/home"
state_home="$tmpdir/state"
toggles_dir="$state_home/omarchy/toggles/hypr"
mkdir -p "$stub_dir" "$home_dir"

for command in hyprctl omarchy-notification-send; do
  printf '#!/bin/bash\nprintf "%%s\\n" "%s $*" >>"%s/commands.log"\n' "$command" "$tmpdir" >"$stub_dir/$command"
done
chmod +x "$stub_dir"/*

run() {
  HOME="$home_dir" XDG_STATE_HOME="$state_home" OMARCHY_PATH="$ROOT" PATH="$stub_dir:$ROOT/bin:$PATH" "$@"
}

[[ $(run omarchy-hyprland-window-transparency) == "transparent" ]] || fail "windows start out transparent"
pass "windows start out transparent"

run omarchy-hyprland-window-transparency glassy
[[ $(run omarchy-hyprland-window-transparency) == "glassy" ]] || fail "glassy windows are reported"
cmp -s "$ROOT/default/hypr/toggles/window-glassy.lua" "$toggles_dir/window-glassy.lua" || fail "glassy windows are loaded after the theme"
grep -qx 'hyprctl reload' "$tmpdir/commands.log" || fail "new transparency reloads Hyprland"
pass "glassy windows override the theme"

run omarchy-hyprland-window-transparency opaque
[[ $(run omarchy-hyprland-window-transparency) == "opaque" ]] || fail "opaque windows are reported"
[[ ! -e $toggles_dir/window-glassy.lua ]] || fail "opaque windows replace glassy ones"
pass "opaque windows replace glassy ones"

run omarchy-hyprland-window-transparency transparent
[[ $(run omarchy-hyprland-window-transparency) == "transparent" ]] || fail "transparent windows are reported"
[[ ! -e $toggles_dir/window-opaque.lua ]] || fail "transparent windows drop the override"
pass "transparent windows drop the override"

if run omarchy-hyprland-window-transparency frosted 2>/dev/null; then
  fail "unknown transparency is refused"
fi
pass "unknown transparency is refused"

# Opaque and glassy reach the windows Omarchy makes transparent through its tag.
grep -qF 'tag = "+transparent-window"' "$ROOT/default/hypr/helpers.lua" || fail "transparent windows carry a tag"
for mode in opaque glassy; do
  grep -qF 'o.window({ tag = "transparent-window" }' "$ROOT/default/hypr/toggles/window-$mode.lua" || fail "$mode windows apply to the tagged windows"
done
pass "opaque and glassy apply to the windows Omarchy makes transparent"

# Glass is drawn just for show, so it stands aside while animations are off.
lua_stub="$tmpdir/stub.lua"
cat >"$lua_stub" <<'LUA'
package.path = os.getenv("ROOT") .. "/?.lua;" .. package.path
package.loaded["default.hypr.paths"] = { state_home = os.getenv("STATE_HOME") }
glassy = false
hl = { config = function() glassy = true end, layer_rule = function() end }
o = { window = function() end }
dofile(os.getenv("ROOT") .. "/default/hypr/toggles/window-glassy.lua")
print(glassy and "glassy" or "plain")
LUA
if command -v lua >/dev/null; then
  [[ $(ROOT="$ROOT" STATE_HOME="$state_home" lua "$lua_stub") == "glassy" ]] || fail "glassy windows apply with animations on"
  cp "$ROOT/default/hypr/toggles/no-animations.lua" "$toggles_dir/"
  [[ $(ROOT="$ROOT" STATE_HOME="$state_home" lua "$lua_stub") == "plain" ]] || fail "glassy windows stand aside while animations are off"
  pass "glassy windows stand aside while animations are off"
else
  skip "lua is not installed"
fi
