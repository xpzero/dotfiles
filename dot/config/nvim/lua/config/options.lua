-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local options = {
  foldmethod = "expr", -- fold with nvim_treesitter
  foldexpr = "nvim_treesitter#foldexpr()",
  foldenable = false, -- no fold to be applied when open a file
  foldlevel = 99, -- if not set this, fold will be everywhere
}

-- vim.opt.shortmess:append("c")

for k, v in pairs(options) do
  vim.opt[k] = v
end
