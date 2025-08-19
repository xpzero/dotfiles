return {
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
              "Absolute path: " .. results[1],
              "Path relative to CWD: " .. results[2],
              "Path relative to HOME: " .. results[3],
              "Filename: " .. results[4],
              "Filename without extension: " .. results[5],
              "Extension of the filename: " .. results[6],
            }, { prompt = "Choose to copy to clipboard:" }, function(choice)
              if choice then
                local result = vim.split(choice, ": ")[2]
                -- 将获取到的路径地址放到剪贴板上
                vim.fn.setreg("+", result)
                vim.notify("Copied: " .. result)
                return
              end
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
  -- diff conflict
  {
    "sindrets/diffview.nvim",
  },
  {
    "Exafunction/windsurf.vim",
    event = "BufEnter",
  },
}
