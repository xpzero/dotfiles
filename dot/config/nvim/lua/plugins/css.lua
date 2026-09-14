return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- CSS/SCSS/Less 属性与固定值补全（Mason 包 css-lsp，提供 vscode-css-language-server）
        cssls = {},
      },
    },
  },
}
