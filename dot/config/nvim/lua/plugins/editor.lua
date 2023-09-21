return {
  -- status line.
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      sections = {
        lualine_z = {},
      },
    },
  },
  -- directory tree.
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
        },
        window = {
          mappings = {
            ["y"] = function(state)
              local node = state.tree:get_node()
              local full_path = node.path

              vim.fn.setreg("*", full_path, "c")
            end,
            ["<c-y>"] = function(state)
              local node = state.tree:get_node()
              local full_path = node.path
              local relative_path = full_path:sub(#state.path + 2)
              vim.fn.setreg("*", relative_path, "c")
            end,
            h = "close_node",
            l = "open",
          },
        },
      },
    },
  },
  -- global search
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    },
  },
  -- colorscheme
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "moon",
      transparent = true, -- 背景色透明
      styles = {
        sidebars = "transparent", -- 侧边栏透明
        floats = "transparent", -- 弹窗透明
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      -- match highlight
      highlight = {
        pattern = [[.*<(KEYWORDS)\s*]],
      },
      -- match search
      search = {
        pattern = [[\b(KEYWORDS)\b]],
      },
    },
  },
}
