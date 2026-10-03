-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.python3_host_prog = vim.fn.expand("~/.local/share/jupyter/venvs/neovim-python/bin/python")
vim.env.PATH = vim.fn.expand("~/.local/bin") .. ":" .. vim.env.PATH

-- AI 补全用内联 ghost text（copilot.lua），而不是塞进补全弹窗
vim.g.ai_cmp = false
