return {
  { "hrsh7th/cmp-cmdline" },
  {
    "hrsh7th/nvim-cmp",
    opts = function()
      local cmp = require("cmp")
      -- / 和 ? 搜索缓冲区内容补全
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })
      -- : 命令行补全（路径 + Ex 命令）
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end,
  },
}
