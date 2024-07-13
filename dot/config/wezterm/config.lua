local wezterm = require("wezterm")
local keymap = require("keymap")
local tab_bar = require("tab").tab_bar

return {
	-- leader = keymap.leader,
	-- keys = keymap.keys,

	color_scheme = "Tokyo Night",
	font = wezterm.font_with_fallback({ "MesloLGS NF", "Songti SC" }),
	font_size = 16,
	-- 窗口顶部装饰
	-- window_decorations = "INTEGRATED_BUTTONS|RESIZE",
	window_decorations = "RESIZE",
	native_macos_fullscreen_mode = true,
	window_background_opacity = 0.5,
	-- 配置默认工作目录
	default_cwd = wezterm.home_dir .. "/Documents/workspace",
	hide_tab_bar_if_only_one_tab = true,
	use_fancy_tab_bar = false,
	-- 不显示添加tab的按钮
	show_new_tab_button_in_tab_bar = false,
	tab_max_width = 32,

	initial_cols = 150,
	initial_rows = 50,

	colors = {
		tab_bar = tab_bar,
	},
}
