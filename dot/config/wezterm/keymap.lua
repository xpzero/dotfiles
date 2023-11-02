local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function move_pane(key, mods, direction)
	local event_name = "MovePane_" .. direction
	wezterm.on(event_name, function(window, pane)
		wezterm.log_error(pane:is_alt_screen_active())
		if pane:is_alt_screen_active() then
			window:perform_action(act.SendKey({ key = key, mods = mods }), pane)
		else
			window:perform_action(act.ActivatePaneDirection(direction), pane)
		end

		-- wezterm.log_info("MovePane_" .. direction)
	end)
	return {
		key = key,
		mods = mods,
		action = act.EmitEvent(event_name),
	}
end

-- prefix key
M.leader = { key = "q", mods = "CTRL" }

M.keys = {
	-- using prefix key & split pane
	{ key = "-", mods = "LEADER", action = act.SplitVertical },
	{ key = "|", mods = "LEADER", action = act.SplitHorizontal },
	-- no use prefix key & close/open pane/window
	{ key = "c", mods = "ALT", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "w", mods = "ALT", action = act.SpawnTab("CurrentPaneDomain") },

	-- activate pane
	move_pane("h", "CTRL", "Left"),
	{ key = "j", mods = "CTRL", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "CTRL", action = act.ActivatePaneDirection("Up") },
	move_pane("l", "CTRL", "Right"),
}

return M
