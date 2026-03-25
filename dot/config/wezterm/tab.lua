local wezterm = require("wezterm")

local function formatTabTitle(tab, tabs, panes, config, hover, max_width)
	local function tab_title()
		local current_dir = wezterm.mux.get_pane(tab.active_pane.pane_id):get_current_working_dir()
		return current_dir.file_path:match("([^/]+)$")
	end

	local background = "#1a1b26"
	local foreground = "#c0caf5"
	local edge_foreground = background

	if tab.is_active then
		background = "#7aa2f7"
		foreground = "#e3e5e5"
	elseif hover then
		background = "#1b1b32"
		foreground = "#909090"
	end

	local title = tab_title()

	-- ensure that the titles fit in the available space,
	-- and that we have room for the edges.
	title = wezterm.truncate_right(title, max_width - 2)

	-- The filled in variant of the > symbol
	local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider
	return {
		-- Right border
		{ Background = { Color = tab.is_active and "#7aa2f7" or "#1a1b26" } },
		{ Foreground = { Color = edge_foreground } },
		{ Text = (tab.is_active and tab.tab_index ~= 0) and SOLID_RIGHT_ARROW or " " },

		-- Tab title
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = " " .. title .. " " },

		-- Right border
		{ Background = { Color = "#1a1b26" } },
		{ Foreground = { Color = tab.is_active and "#7aa2f7" or "#c0caf5" } },
		{ Text = tab.is_active and SOLID_RIGHT_ARROW or " " },
	}
end

return {
	setup = function(config)
		config.use_fancy_tab_bar = false
		config.tab_bar_at_bottom = false
		config.tab_max_width = 32
		config.unzoom_on_switch_pane = true
		config.show_new_tab_button_in_tab_bar = false
		config.hide_tab_bar_if_only_one_tab = true

		wezterm.on("format-tab-title", formatTabTitle)
	end,
}
