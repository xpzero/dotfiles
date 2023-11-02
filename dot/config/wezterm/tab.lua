local wezterm = require("wezterm")

local M = {}

M.tab_bar = {
	-- The color of the strip that goes along the top of the window
	-- (does not apply when fancy tab bar is in use)
	background = "#0b0022",

	-- The active tab is the one that has focus in the window
	active_tab = {
		-- The color of the background area for the tab
		bg_color = "#c0c0c0",
		-- The color of the text for the tab
		fg_color = "#839496",

		-- Specify whether you want "Half", "Normal" or "Bold" intensity for the
		-- label shown for this tab.
		-- The default is "Normal"
		intensity = "Bold",

		-- Specify whether you want "None", "Single" or "Double" underline for
		-- label shown for this tab.
		-- The default is "None"
		underline = "None",

		-- Specify whether you want the text to be italic (true) or not (false)
		-- for this tab.  The default is false.
		italic = false,

		-- Specify whether you want the text to be rendered with strikethrough (true)
		-- or not for this tab.  The default is false.
		strikethrough = false,
	},

	-- Inactive tabs are the tabs that do not have focus
	inactive_tab = {
		bg_color = "#1b1032",
		fg_color = "#808080",
		intensity = "Bold",

		-- The same options that were listed under the `active_tab` section above
		-- can also be used for `inactive_tab`.
	},

	-- You can configure some alternate styling when the mouse pointer
	-- moves over inactive tabs
	inactive_tab_hover = {
		bg_color = "#3b3052",
		fg_color = "#909090",
		italic = true,

		-- The same options that were listed under the `active_tab` section above
		-- can also be used for `inactive_tab_hover`.
	},

	-- The new tab button that let you create new tabs
	new_tab = {
		bg_color = "#1b1032",
		fg_color = "#808080",

		-- The same options that were listed under the `active_tab` section above
		-- can also be used for `new_tab`.
	},

	-- You can configure some alternate styling when the mouse pointer
	-- moves over the new tab button
	new_tab_hover = {
		bg_color = "#3b3052",
		fg_color = "#909090",
		italic = true,

		-- The same options that were listed under the `active_tab` section above
		-- can also be used for `new_tab_hover`.
	},
}

-- The filled in variant of the > symbol
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.pl_left_hard_divider
-- The filled in variant of the < symbol
local SOLID_LEFT_ARROW = wezterm.nerdfonts.pl_right_hard_divider

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s)
	return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
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

return M
