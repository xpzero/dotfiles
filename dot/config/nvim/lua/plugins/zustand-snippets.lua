return {
  {
    "L3MON4D3/LuaSnip",
    opts = function()
      local ls = require("luasnip")
      local parse = ls.parser.parse_snippet

      local snippets = {
        parse(
          "zstore",
          table.concat({
            "import { create } from 'zustand';",
            "",
            "interface ${1:Name}State {",
            "\t${2}",
            "}",
            "",
            "export const use${1:Name}Store = create<${1:Name}State>()((set, get) => ({",
            "\t${3}",
            "}));",
          }, "\n")
        ),
        parse("zsel", "const ${2:value} = use${1:Name}Store((s) => s.${2:value});"),
        parse("zset", "set({ ${1:key: value} });"),
        parse(
          "zact",
          table.concat({ "${1:actionName}: async () => {", "\t${2}", "\tset({ ${3} });", "}," }, "\n")
        ),
      }

      -- zustand 片段：store 定义在 .ts，使用在 .tsx，两种 filetype 都注册
      ls.add_snippets("typescript", snippets)
      ls.add_snippets("typescriptreact", vim.deepcopy(snippets))
    end,
  },
}
