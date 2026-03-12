local wezterm = require("wezterm")
local config = wezterm.config_builder()

require("tab").setup(config)
require("keymap").setup(config)

-- font
config.font_size = 20
config.font_dirs = { "../../../assets/fonts" }
config.font = wezterm.font_with_fallback({
	"JetBrains Mono",
	"FiraCode Nerd Font Mono",
})

-- config.window_background_image = wezterm.home_dir .. "/Documents/dotfiles/assets/img/code-background.jpg"
config.window_background_opacity = 0.9
config.macos_window_background_blur = 20
config.color_scheme = "tokyonight_night"
config.window_decorations = "RESIZE"

-- config.background = {
-- 	{
-- 		-- 背景图片路径（请替换为你自己的实际路径）
-- 		source = { File = wezterm.home_dir .. "/Documents/dotfiles/assets/img/code-background.jpg" },
--
-- 		-- 图片亮度和饱和度微调 (HSB)
-- 		-- 建议降低亮度(brightness)以确保文字可读性，武侠风格可适当调低饱和度(saturation)
-- 		hsb = {
-- 			brightness = 0.05, -- 0.05 表示很暗，适合作为背景
-- 			hue = 1.0,
-- 			saturation = 0.8,
-- 		},
--
-- 		-- 图片缩放模式："AspectFill" 填充不拉伸, "Cover" 覆盖, "None" 原始大小
-- 		attachment = "Fixed",
-- 		width = "100%",
-- 		height = "100%",
-- 	},
-- }

-- 默认工作目录
config.default_cwd = wezterm.home_dir .. "/Documents/workspace"

return config
