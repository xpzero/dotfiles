return {
  {
    "benlubas/molten-nvim",
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 24
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
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
      { "<leader>mx", "<cmd>MoltenExportOutput<cr>", desc = "Notebook: Export Outputs to .ipynb", ft = "python" },
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
    -- kitty 后端即 kitty 图形协议，WezTerm 兼容实现；图片缩放依赖 brew 的 imagemagick
    "3rd/image.nvim",
    build = false,
    opts = {
      backend = "kitty",
      max_width = 100,
      max_height = 16,
      max_height_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
    },
  },
  {
    -- Jupyter 内核补全，普通模式 <C-x><C-o> 触发 omnifunc
    "lkhphuc/jupyter-kernel.nvim",
    opts = {},
  },
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false,
    opts = {
      force_ft = "python",
    },
  },
}
