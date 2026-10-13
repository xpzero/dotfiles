return {
  -- directory tree.
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      window = {
        position = "float",
        float = {
          relative = "editor",
          border = "rounded",
          width = 80,
          height = "80%",
          col = 10,
          row = 5,
        },
      },
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
        },
        commands = {
          copy_selector = function(state)
            -- 整体 pcall：任何一步出错都转成可读通知，不再抛 E5108 堆栈
            local ok, err = pcall(function()
              -- 大目录扫描渲染完成前 state.tree 为 nil，此时触发会直接报 E5108
              if not state.tree then
                vim.notify("neo-tree: 文件树尚未加载完成，稍后再试", vim.log.levels.WARN)
                return
              end
              local node = state.tree:get_node()
              if not node then
                return
              end
              local filepath = node:get_id()
              local filename = node.name or filepath
              local modify = vim.fn.fnamemodify

              local results = {
                filepath,
                modify(filepath, ":."),
                modify(filepath, ":~"),
                filename,
                modify(filename, ":r"),
                modify(filename, ":e"),
              }
              local labels = {
                "Absolute path",
                "Path relative to CWD",
                "Path relative to HOME",
                "Filename",
                "Filename without extension",
                "Extension of the filename",
              }
              local items = {}
              for i, label in ipairs(labels) do
                items[i] = label .. ": " .. tostring(results[i])
              end

              local function on_choice(_, idx)
                -- 取消选择（Esc / Ctrl-C）时 idx 为 nil，静默退出
                if not idx then
                  return
                end
                local result = results[idx]
                -- 没有扩展名的文件，":e" 结果为空串，复制无意义
                if not result or result == "" then
                  vim.notify("该项没有可复制的值（如文件无扩展名）", vim.log.levels.WARN)
                  return
                end
                -- 将获取到的路径地址放到剪贴板上
                vim.fn.setreg("+", result)
                vim.notify("Copied: " .. result)
              end

              -- 用 snacks 的选择器替代 vim.ui.select（已被 fzf-lua 接管为终端浮窗）：
              -- snacks 是纯 Lua 浮窗，取消时走干净的 on_close 回调，
              -- Ctrl-C 中断 fzf 终端进程导致的报错在这里不存在
              local snacks_ok, snacks_picker = pcall(require, "snacks.picker")
              if snacks_ok and snacks_picker.select then
                snacks_picker.select(items, { prompt = "复制路径到剪贴板" }, on_choice)
              else
                vim.ui.select(items, { prompt = "Choose to copy to clipboard:" }, on_choice)
              end
            end)
            if not ok then
              vim.notify("copy_selector 出错: " .. tostring(err), vim.log.levels.ERROR)
            end
          end,
        },
        window = {
          mappings = {
            Y = "copy_selector",
            h = "close_node",
            l = "open",
            -- 使用 Ctrl 组合键进行导航，避免与默认快捷键冲突
            ["<C-h>"] = "navigate_up",
            ["<C-l>"] = "none", -- 让 smart-splits 处理右移
            ["<C-j>"] = "none", -- 让 smart-splits 处理下移
            ["<C-k>"] = "none", -- 让 smart-splits 处理上移
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
    "mrjones2014/smart-splits.nvim",
    config = function()
      require("smart-splits").setup({
        multiplexerIntegration = "zellij", -- 改为 zellij 因为你在 zellij 中使用
        ignore_single_chdir = true,
        at_edge = "stop", -- zellij 集成不支持 wrap
        -- 确保在 neo-tree 等特殊窗口中也能正常工作
        disabled_filetypes = {},
      })
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
    "gitsigns.nvim",
    opts = {
      current_line_blame = true,
    },
  },
}
