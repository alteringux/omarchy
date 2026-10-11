-- Frosted glass: transparent windows let more through, blurred, as do the
-- shell's surfaces wherever a theme makes them translucent.

-- Turning animations off asks for nothing drawn just for show, and toggles load
-- in name order, so the glass has to stand aside for no-animations itself.
local paths = require("default.hypr.paths")
local no_animations = io.open(paths.state_home .. "/omarchy/toggles/hypr/no-animations.lua", "r")
if no_animations then
  no_animations:close()
  return
end

hl.config({
  decoration = {
    blur = {
      enabled = true,
      size = 4,
      passes = 2,
      new_optimizations = true,
      xray = false,
      contrast = 1.0,
      brightness = 0.75,
      noise = 0.01,
      vibrancy = 0.35,
      vibrancy_darkness = 0.35,
      popups = true,
      special = true,
    },
  },
})

o.window({ tag = "transparent-window" }, { opacity = "0.75 0.75" })

hl.layer_rule({
  match = { namespace = "^(omarchy-bar|omarchy-menu|omarchy-notifications|omarchy-osd|omarchy-polkit|omarchy-reminders|omarchy-clipboard|omarchy-emojis|omarchy-image-selector|omarchy-keyboard-panel|omarchy-network-qr)$" },
  blur = true,
  ignore_alpha = 0.3,
})
