# 💤 LazyVim

A starter template for [LazyVim](https://github.com/LazyVim/LazyVim).
Refer to the [documentation](https://lazyvim.github.io/installation) to get started.

# Introdution about the effect of plugins

There are some plugins are very useful below.
## nvm-lspconfig.nvim

`LSP`是一种协议，如果IDE或文本编辑器实现了`LSP`协议，就可以提供代码自动完成、定义跳转等功能

`Neovim`本身已实现了`LSP`协议，且其配置过程也并不复杂，只要让`Neovim`启动语言服务然后进行设置即可。

但是会有以下问题
> 我们可能会用到很多种编程语言，要给每种编程语言都手动配置一遍，是个很繁杂的劳动。
> 对于某种语言的配置，大部分的时候大部分人的配置应该是差不多的，是可以共享的。

所以`Neovim`官方提供了`nvm-lspconfig`插件，解决了上述的两个问题，提供了一些基础的配置，方便了用户配置。

## mason.nvim

即使有了`nvm-lspconfig`插件，但是还是有下面这些的不方便

> 我们还需要手动安装 Language Server
> 手动启用对应的 Language Server 的配置。

`mason`插件提供了`UI`和命令，可以用来安装一些工具的语言服务。

## mason-lspconfig.nvim

可以让`mason`插件安装的语言服务自动启用`nvm-lspconfig`的配置。

## bufferline

可以让编辑区域上方出现文件名。如果切换/更新文件`buffer`后，上方文件名右侧会显示图标以区分该文件的状态。

## lualine

在`Neovim`的底部显示`Neovim`及当前编辑文件的一些状态。

## alpha-vim

`Neovim`的欢迎页。在终端仅输入`nvim`即可

## nvim-cmp

虽然`Neovim`内置自动补全，但用起来不是很方便。该插件是一个补全引擎，整合补全源作为补全结果显示。

## indent-blackline

配置缩进线的显示与样式

## gitsigns

配置git的变更记录、样式等

## diffview

用来处理git冲突最合适

## neo-tree

显示文件缩在目录树

## which-key
快捷键智能提示，方便快捷键的使用

## treesitter
代码语法高亮

## telescope
文件搜索

## tokyonight.nvim
一个暗色主题

## todo-comments.nvim
高亮`todo`等特标提示


# 引用
[Neovim Language Server Protocol 配置解释](https://blog.otakusaikou.com/2023/07/05/neovim-language-server-config-explanation/)
