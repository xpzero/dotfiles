local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- 按键透传检测：vim 系编辑器和 zellij 内，按键交给内部程序处理
local function is_passthrough(pane)
	local process_info = pane:get_foreground_process_info()
	if not process_info then
		return false
	end

	local process_name = process_info.name
	return process_name == "nvim"
		or process_name == "vim"
		or process_name == "vi"
		or process_name == "zellij"
end

local function move_pane(key, mods, direction)
	local event_name = "MovePane_" .. direction
	wezterm.on(event_name, function(window, pane)
		-- 使用改进的vim检测
		if is_passthrough(pane) then
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

-- 切换 wezterm 标签页；zellij/vim 内透传按键（zellij 用 Alt+h/l 移动面板焦点）
local function switch_tab(key, mods, relative)
	local event_name = "SwitchTab_" .. key .. "_" .. relative
	wezterm.on(event_name, function(window, pane)
		if is_passthrough(pane) then
			window:perform_action(act.SendKey({ key = key, mods = mods }), pane)
		else
			window:perform_action(act({ ActivateTabRelative = relative }), pane)
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
	switch_tab("l", "ALT", 1),
	switch_tab("h", "ALT", -1),
}

M.setup = function(config)
	config.leader = M.leader
	config.keys = M.keys
end

return M
