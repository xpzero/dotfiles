local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- 改进的vim检测函数
local function is_vim(pane)
	local process_info = pane:get_foreground_process_info()
	if not process_info then
		return false
	end

	local process_name = process_info.name
	-- 检测常见的编辑器进程
	return process_name == "nvim" or process_name == "vim" or process_name == "vi"
end

local function move_pane(key, mods, direction)
	local event_name = "MovePane_" .. direction
	wezterm.on(event_name, function(window, pane)
		-- 使用改进的vim检测
		if is_vim(pane) then
			-- 如果在vim/nvim中，发送键位给编辑器
			window:perform_action(act.SendKey({ key = key, mods = mods }), pane)
		else
			-- 如果不在vim中，切换wezterm pane
			window:perform_action(act.ActivatePaneDirection(direction), pane)
		end
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
	-- { key = "w", mods = "ALT", action = act.SpawnTab("CurrentPaneDomain") },

	-- activate pane (在 zellij 中使用，禁用这些快捷键让 nvim 处理)
	-- move_pane("h", "CTRL", "Left"),
	-- move_pane("j", "CTRL", "Down"),
	-- move_pane("k", "CTRL", "Up"),
	-- move_pane("l", "CTRL", "Right"),

	-- switch tab
	{ key = "l", mods = "ALT", action = act({ ActivateTabRelative = 1 }) },
	{ key = "h", mods = "ALT", action = act({ ActivateTabRelative = -1 }) },
}

M.setup = function(config)
	config.leader = M.leader
	config.keys = M.keys
end

return M
