return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim",
      "stevearc/dressing.nvim",
    },
    opts = function()
      return require("user.codecompanion") -- 把配置独立出去，保持整洁
    end,
    keys = {
      {
        "<leader>kk",
        function()
          require("codecompanion").prompt("greet")
        end,
        desc = "Kimi Chat",
      },
      {
        "<leader>ki",
        ":'<,'>CodeCompanion<cr>",
        desc = "Kimi Inline",
        mode = "v",
      },
      { "<leader>ka", "<cmd>CodeCompanionActions<cr>", desc = "Kimi Actions" },
    },
  },
}
