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
	config.tab_bar_at_bottom = false
	config.hide_tab_bar_if_only_one_tab = true
	config.tab_max_width = 32
	config.unzoom_on_switch_pane = true
	config.show_new_tab_button_in_tab_bar = false

	local RIGHT_BORDER = ""

	local function tab_title(tab_info)
		local title = tab_info.tab_title
		-- if the tab title is explicitly set, take that
		if title and #title > 0 then
			return title
		end
		-- Otherwise, use the title from the active pane
		-- in that tab
		return tab_info.active_pane.title
	end

	wezterm.on("format-tab-title", function(tab, _, _, _, hover, max_width)
		-- local edge_background = "#2a2a40"
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

		local title = tab_title(tab)

		-- ensure that the titles fit in the available space,
		-- and that we have room for the edges.
		title = wezterm.truncate_right(title, max_width - 2)

		return {
			-- Right border
			{ Background = { Color = tab.is_active and "#7aa2f7" or "#1a1b26" } },
			{ Foreground = { Color = edge_foreground } },
			{ Text = (tab.is_active and tab.tab_index ~= 0) and RIGHT_BORDER or " " },

			-- Tab title
			{ Background = { Color = background } },
			{ Foreground = { Color = foreground } },
			{ Text = " " .. title .. " " },

			-- Right border
			{ Background = { Color = "#1a1b26" } },
			{ Foreground = { Color = tab.is_active and "#7aa2f7" or "#c0caf5" } },
			{ Text = tab.is_active and RIGHT_BORDER or " " },

			-- If you want, add more stuff to the tab bar.
		}
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
