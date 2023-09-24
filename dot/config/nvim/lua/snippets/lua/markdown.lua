local ls = require("luasnip")
local fmt = require("luasnip.extras.fmt").fmt
ls.add_snippets("markdown", {
  ls.snippet(
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
  ),
})
