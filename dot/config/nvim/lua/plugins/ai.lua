return {
  {
    "Exafunction/windsurf.nvim",
    event = "InsertEnter",
    main = "codeium", -- 仓库改名 windsurf 后 lua 模块仍叫 codeium，须显式指定
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      enable_cmp_source = false,
      virtual_text = {
        enabled = true,
        key_bindings = {
          accept = false, -- Tab 采纳由 blink.cmp 的 ai_accept 接线处理
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
    },
  },
  {
    "Exafunction/windsurf.nvim",
    opts = function()
      LazyVim.cmp.actions.ai_accept = function()
        if require("codeium.virtual_text").get_current_completion_item() then
          LazyVim.create_undo()
          vim.api.nvim_input(require("codeium.virtual_text").accept())
          return true
        end
      end
    end,
  },
}
