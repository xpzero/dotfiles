local wezterm = require("wezterm")
local config = wezterm.config_builder()

require("tab").setup(config)
require("keymap").setup(config)

-- font
config.font_size = 16
config.font = wezterm.font_with_fallback({
	"MesloLGS NF",
	"JetBrainsMonoNL Nerd Font Mono",
})

config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
config.window_background_opacity = 0.5
config.color_scheme = "tokyonight_night"
config.window_decorations = "RESIZE"

-- 默认工作目录
config.default_cwd = wezterm.home_dir .. "/Documents/workspace"

return config
