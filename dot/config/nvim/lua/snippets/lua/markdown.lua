local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt

local tt = ls.snippet(
  "tt",
  fmt(
    [[ 
    ---
    title: {xxx}
    ---
    ]],
    {
      xxx = ls.function_node(function()
        -- :t get trailing string with extension.
        -- :r get the string of before extension.
        -- return vim.fn.fnamemodify(vim.fn.bufname(), ":t:r")
        -- or below. source: https://neovim.io/doc/user/builtin.html#expand()
        return vim.fn.expand("%:t:r")
      end),
    }
  )
)

local tabs = ls.snippet(
  "tabs",
  fmt(
    [[
<Tabs defaultValue="{}">
  <TabItem value="{}">
{}
  </TabItem>
</Tabs>
]],
    {
      ls.insert_node(1),
      ls.insert_node(2),
      ls.insert_node(3),
    }
  )
)

ls.add_snippets("markdown", { tt, tabs })
