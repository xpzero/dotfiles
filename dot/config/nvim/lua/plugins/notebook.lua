return {
  {
    "benlubas/molten-nvim",
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_image_provider = "none"
      vim.g.molten_output_win_max_height = 20
    end,
    keys = {
      { "<leader>mi", "<cmd>MoltenInit<cr>", desc = "Notebook: Initialize Kernel", ft = "python" },
      {
        "<leader>ma",
        function()
          vim.fn.MoltenEvaluateRange(1, vim.api.nvim_buf_line_count(0))
        end,
        desc = "Notebook: Run All",
        ft = "python",
      },
      { "<leader>ml", "<cmd>MoltenEvaluateLine<cr>", desc = "Notebook: Run Line", ft = "python" },
      { "<leader>mo", "<cmd>MoltenShowOutput<cr>", desc = "Notebook: Show Output", ft = "python" },
      { "<leader>mh", "<cmd>MoltenHideOutput<cr>", desc = "Notebook: Hide Output", ft = "python" },
      { "<leader>mr", "<cmd>MoltenRestart<cr>", desc = "Notebook: Restart Kernel", ft = "python" },
      {
        "<leader>mv",
        ":<C-u>MoltenEvaluateVisual<cr>gv",
        desc = "Notebook: Run Selection",
        mode = "v",
        ft = "python",
      },
    },
  },
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false,
    opts = {
      force_ft = "python",
    },
  },
}
