return {
  -- 翻译插件：光标下单词 / 选中内容翻译，浮窗展示
  {
    "uga-rosa/translate.nvim",
    cmd = "Translate",
    keys = {
      { "<leader>t", "viw:Translate zh<CR>", mode = "n", desc = "翻译光标下单词", silent = true },
      { "<leader>t", "<Cmd>Translate zh<CR>", mode = "x", desc = "翻译选中内容", silent = true },
      { "<leader>tr", "<Cmd>Translate zh -output=replace<CR>", mode = "x", desc = "翻译并替换选中内容", silent = true },
    },
    opts = {
      default = {
        command = "translate_shell", -- 引擎走本地 trans 命令，不依赖插件作者的中转服务
      },
      preset = {
        output = {
          floating = {
            relative = "cursor", -- 相对光标定位
            row = 1, -- 光标（单词）正下方
            col = 0, -- 与光标对齐
            border = "rounded",
          },
        },
      },
    },
  },
}
