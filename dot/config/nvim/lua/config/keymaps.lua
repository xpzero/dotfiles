-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

-- navigation to wezterm panes using smart-splits.nvim
-- 这些快捷键可以在 neovim 窗口、neo-tree 和 wezterm pane 之间无缝穿梭
map("n", "<C-h>", function()
  require("smart-splits").move_cursor_left()
end, { desc = "Go to left window/pane" })
map("n", "<C-j>", function()
  require("smart-splits").move_cursor_down()
end, { desc = "Go to lower window/pane" })
map("n", "<C-k>", function()
  require("smart-splits").move_cursor_up()
end, { desc = "Go to upper window/pane" })
map("n", "<C-l>", function()
  require("smart-splits").move_cursor_right()
end, { desc = "Go to right window/pane" })
