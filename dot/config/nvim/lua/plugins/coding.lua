return {
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      -- load friendly-snippets
      require("luasnip.loaders.from_vscode").lazy_load()
      -- load VS Code-like snippets.
      require("luasnip.loaders.from_vscode").lazy_load({ paths = { "./lua/snippets/vscode" } })
      -- load lua snippets
      require("luasnip.loaders.from_lua").lazy_load({ paths = "./lua/snippets/lua" })
    end,
  },
}
