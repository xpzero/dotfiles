# Neovim + Jupyter 环境说明与故障恢复

Neovim 下的 Jupyter notebook 工作流：jupytext 负责文件转换，molten 负责内核执行与内联输出，image.nvim 负责图表渲染，jupyter-kernel.nvim 提供内核补全。

## 架构与文件位置

| 组件 | 位置 | 作用 |
|---|---|---|
| 插件配置 | `~/.config/nvim/lua/plugins/notebook.lua` | 四个插件的声明、选项、快捷键 |
| Python host | `~/.config/nvim/lua/config/options.lua` 的 `vim.g.python3_host_prog` | 指向下面的专用 venv，molten 远程插件跑在这里 |
| 专用 venv | `~/.local/share/jupyter/venvs/neovim-python` | molten + jupyter 运行环境（pynvim/jupyter_client/ipykernel/nbformat/pillow/pyperclip） |
| kernelspec | `~/Library/Jupyter/kernels/neovim-python` | 名为 "Python (neovim)" 的内核注册项 |
| 图片依赖 | WezTerm 终端 + `brew install imagemagick` | image.nvim 的 kitty 图形协议后端 + 图片缩放 |

插件本体在 `~/.local/share/nvim/lazy/`（molten-nvim / jupytext.nvim / image.nvim / jupyter-kernel.nvim），版本锁定在 `~/.config/nvim/lazy-lock.json`。

## 日常工作流

```text
nvim xxx.ipynb            # 自动转成带 # %% 标记的 python 缓冲区（jupytext.nvim）
<leader>mi                # 启动内核：选 "Python (neovim)" 或直接给项目 venv 路径
<leader>ml / mv / ma      # 跑当前行 / 跑选中 / 全部运行
<leader>mo / mh           # 显示 / 隐藏输出窗口
<leader>mr                # 重启内核
<leader>mx                # 把输出导出回 .ipynb（同事可在 Jupyter 里看到）
:w                        # jupytext 自动把改动同步回 .ipynb，不丢输出
```

项目自己的 venv 要跑 notebook 的话，里面必须有 ipykernel。virtualenv 创建的 venv 没有 pip，用 uv 装：

```bash
uv pip install --python /path/to/.venv/bin/python ipykernel
```

## 故障恢复

### 1. venv 坏掉（最常见：Homebrew 升级 Python 之后）

症状：`<leader>mi` 报错；`nvim --headless` 启动时远程插件加载失败；`.../neovim-python/bin/python -m pip` 报 `No module named pip`。

修复——重建 venv 并重装依赖、重注册内核：

```bash
rm -rf ~/.local/share/jupyter/venvs/neovim-python
/opt/homebrew/bin/python3 -m venv ~/.local/share/jupyter/venvs/neovim-python
~/.local/share/jupyter/venvs/neovim-python/bin/pip install \
  pynvim jupyter_client ipykernel nbformat pillow pyperclip
~/.local/share/jupyter/venvs/neovim-python/bin/python -m ipykernel install --user \
  --name neovim-python --display-name "Python (neovim)"
```

注意：venv 路径不要改，`options.lua` 里的 `python3_host_prog` 指向它。

### 2. ImageMagick 缺失（图片不显示，报 magick 相关错误）

```bash
brew install imagemagick
```

Homebrew 走 ghcr.io 下载，网络不通时多重试几次即可（自带断点续传）。macOS 没有 `timeout` 命令，写脚本时别用。

### 3. 图片后端

`notebook.lua` 里 image.nvim 的 backend 必须是 `"kitty"`（kitty 图形协议，WezTerm 兼容实现）。新版 image.nvim 已移除 `"wezterm"` 后端选项，不要改回去。图片显示必须直接在 WezTerm 里跑 nvim；tmux 下 kitty 协议需要额外配 passthrough，否则不渲染。

### 4. 打开 .ipynb 没有语法高亮、<leader>m* 快捷键全部无效

症状：打开时闪过 `Error in BufReadCmd Autocommands for "*.ipynb"`，有时带 `attempt to index field 'kernelspec'`。

原因：该文件不是合法的 notebook JSON（扩展名是 .ipynb 的普通脚本），或 notebook 缺 `metadata.kernelspec` 字段（手工用 nbformat 生成的裸文件常见）。jupytext.nvim 解析崩溃，缓冲区保持原始内容，ft 不是 python，所有 `ft = "python"` 限定的键位都不存在。

诊断与修复：

```bash
file xxx.ipynb                      # 正常 notebook 应显示 "JSON data"
jupytext --set-kernel python3 xxx.ipynb   # 补 kernelspec 元数据
```

如果 `file` 显示是 Python script 而非 JSON，说明文件名和内容不符：把内容挪回 `.py`，用 jupytext 转换：

```bash
jupytext --to ipynb xxx.py          # 从带 # %% 标记的 py 生成 notebook
jupytext --set-kernel python3 xxx.ipynb
```

注意：`jupytext --set-kernel` 需要 jupytext 自己的环境里有 jupyter_client，uv tool/pipx 装的 jupytext 默认没有；此时用装了 nbformat 的 venv 直接改 metadata 也可以。

### 5. 快速自检命令

```bash
# venv 健康
~/.local/share/jupyter/venvs/neovim-python/bin/python -c "import pynvim, jupyter_client, ipykernel; print('ok')"
# molten 远程插件已注册（有输出即正常）
grep -c Molten ~/.local/share/nvim/rplugin.vim
# nvim 内部：打开 .ipynb 后检查
#   :echo &filetype                → python
#   :echo maparg(' ma', 'n')       → 非空（<leader> 是空格）
```

## 已知边界

- jupytext.nvim 解析 .ipynb 时假定 `metadata.kernelspec` 一定存在，无容错；遇到就按上面第 4 条修。
- PyCharm 的变量面板、cell 级调试器、ipywidgets 在 Neovim 里没有等价物；探索性分析可留在 IDE，代码向工作流用本套配置。
