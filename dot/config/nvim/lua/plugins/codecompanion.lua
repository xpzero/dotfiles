return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionCmd", "CodeCompanionActions" },
  keys = {
    { "<C-a>", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "AI: 动作面板" },
    { "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "AI: 聊天" },
  },
  opts = function()
    return require("user.codecompanion")
  end,
  init = function()
    vim.cmd([[cab cc CodeCompanion]])
  end,
}
