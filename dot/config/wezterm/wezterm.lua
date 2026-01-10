local wezterm = require("wezterm")
local config = wezterm.config_builder()

require("tab").setup(config)
require("keymap").setup(config)

-- font
config.font_size = 16
config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"FiraCode Nerd Font Mono",
})

config.window_padding = { left = 5, right = 5, top = 5, bottom = 0 }
config.window_background_opacity = 0.9
config.color_scheme = "tokyonight_night"
config.window_decorations = "RESIZE"

-- 默认工作目录
config.default_cwd = wezterm.home_dir .. "/Documents/workspace"

return config
