local wezterm = require("wezterm")

-- The filled in variant of the > symbol
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider
-- The filled in variant of the < symbol
local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s)
	if s == nil then
		return ""
	end
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

local M = {}
M.setup = function(config)
	config.use_fancy_tab_bar = false
	config.tab_bar_at_bottom = true
	config.hide_tab_bar_if_only_one_tab = true
	config.tab_max_width = 32
	config.unzoom_on_switch_pane = true
	config.show_new_tab_button_in_tab_bar = false

	wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
		wezterm.log_info("tab", tab.tab_title)
		wezterm.log_info("tab-dir", tab.active_pane.current_working_dir)
		wezterm.log_info("panes", panes)
		-- 获取当前工作目录
		local title = basename(tab.active_pane.current_working_dir)
		local style = {}
		if tab.is_active then
			style = {
				{ Background = { Color = "#ede8d7" } },
				{ Foreground = { Color = "#4386f7" } },
				{ Text = " " .. tab.tab_index .. " " },

				{ Background = { Color = "#4386f7" } },
				{ Foreground = { Color = "#ede8d7" } },
				{ Text = SOLID_RIGHT_ARROW },

				{ Background = { Color = "#4386f7" } },
				{ Foreground = { Color = "#fff" } },
				{ Text = " " .. title .. " " },

				{ Background = { Color = "#0b0022" } },
				{ Foreground = { Color = "#4386f7" } },
				{ Text = SOLID_RIGHT_ARROW },
			}
		else
			style = {

				{ Background = { Color = "#ede8d7" } },
				{ Foreground = { Color = "#0b0022" } },
				{ Text = " " .. tab.tab_index .. " " },

				{ Background = { Color = "#96a1a1" } },
				{ Foreground = { Color = "#ede8d7" } },
				{ Text = SOLID_RIGHT_ARROW },

				{ Background = { Color = "#96a1a1" } },
				{ Foreground = { Color = "#0b0022" } },
				{ Text = " " .. title .. " " },

				{ Background = { Color = "#0b0022" } },
				{ Foreground = { Color = "#96a1a1" } },
				{ Text = SOLID_RIGHT_ARROW },
			}
		end

		local separator = {
			{ Background = { Color = "#ede8d7" } },
			{ Foreground = { Color = "#0b0022" } },
			{ Text = SOLID_RIGHT_ARROW },
		}

		if tab.tab_index ~= 0 then
			for i = 1, #separator do
				table.insert(style, i, separator[i])
			end
		end
		return style
	end)

	wezterm.on("update-right-status", function(window, pane)
		-- Each element holds the text for a cell in a "powerline" style << fade
		local cells = {}

		-- I like my date/time in this style: "Wed Mar 3 08:14"
		local date = wezterm.strftime("%a %b %-d")
		table.insert(cells, date)
		table.insert(cells, wezterm.strftime("%H:%M"))

		-- Color palette for the backgrounds of each cell
		local colors = {
			"#3c1361",
			"#52307c",
			"#663a82",
			"#7c5295",
			"#b491c8",
		}

		-- Foreground color for the text across the fade
		local text_fg = "#c0c0c0"
		-- The elements to be formatted
		local elements = {}
		-- How many cells have been formatted
		local num_cells = 0

		-- Translate a cell into elements
		local function push(text, is_last)
			local cell_no = num_cells + 1
			table.insert(elements, { Foreground = { Color = text_fg } })
			table.insert(elements, { Background = { Color = colors[cell_no] } })
			table.insert(elements, { Text = " " .. text .. " " })
			if not is_last then
				table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
				table.insert(elements, { Text = SOLID_LEFT_ARROW })
			end
			num_cells = num_cells + 1
		end

		while #cells > 0 do
			local cell = table.remove(cells, 1)
			push(cell, #cells == 0)
		end

		window:set_right_status(wezterm.format(elements))
	end)
end

return M
