return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        hide_dotfiles = false,
      },
      window = {
        mappings = {
          ["Y"] = function(state)
            local node = state.tree:get_node()
            local full_path = node.path

            vim.fn.setreg("*", full_path, "c")
          end,
          ["<C-y>"] = function(state)
            local node = state.tree:get_node()
            local full_path = node.path
            local relative_path = full_path:sub(#state.path + 2)
            vim.fn.setreg("*", relative_path, "c")
          end,
        },
      },
    },
  },
}
