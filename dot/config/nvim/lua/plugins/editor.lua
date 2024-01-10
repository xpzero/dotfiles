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
        commands = {
          copy_selector = function(state)
            local node = state.tree:get_node()
            local filepath = node:get_id()
            local filename = node.name
            local modify = vim.fn.fnamemodify

            local results = {
              filepath,
              modify(filepath, ":."),
              modify(filepath, ":~"),
              filename,
              modify(filename, ":r"),
              modify(filename, ":e"),
            }

            vim.ui.select({
              "1. Absolute path: " .. results[1],
              "2. Path relative to CWD: " .. results[2],
              "3. Path relative to HOME: " .. results[3],
              "4. Filename: " .. results[4],
              "5. Filename without extension: " .. results[5],
              "6. Extension of the filename: " .. results[6],
            }, { prompt = "Choose to copy to clipboard:" }, function(choice)
              local i = tonumber(choice:sub(1, 1))
              local result = results[i]
              vim.fn.setreg("+", result)
              vim.notify("Copied: " .. result)
            end)
          end,
        },
        window = {
          mappings = {
            Y = "copy_selector",
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
      transparent = true, -- background transparent.
      styles = {
        sidebars = "transparent", -- sidebars transparent.
        floats = "transparent", -- floats transparent
      },
    },
  },
  {
    "aserowy/tmux.nvim",
    config = function()
      return require("tmux").setup()
    end,
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
  {
    "numToStr/Comment.nvim",
    opts = {
      -- add any options here
    },
    lazy = false,
  },
  {
    "TobinPalmer/rayso.nvim",
    cmd = { "Rayso" },
    config = function()
      require("rayso").setup({})
    end,
  },
}
