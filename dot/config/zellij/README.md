# 需求工作区管理工具

基于 Git worktree + Zellij session 的多需求并行开发管理工具。

## 核心特性

- **多个需求并行**：每个需求独立的工作目录、Zellij session、窗口布局
- **快速切换**：一条命令切换到任意需求，自动 detach/attach Zellij session
- **软链共享 node_modules**：默认软链到主仓库 `node_modules`，0 磁盘开销，秒级启动；需要单独改依赖时用 `req-isolate` 升级为独立模式
- **自动布局**：每个需求预定义 nvim + terminal 窗口布局，进入即可用
- **分支隔离**：使用 git worktree，多个需求可以同时 checkout 同一仓库的不同分支
- **依赖漂移提醒**：`zj` attach 前自动检测 worktree 与主仓库 lock 文件是否一致

## 命令

| 命令 | 说明 |
|------|------|
| `zj <name>` | 切换到指定需求。如果不存在则创建 session，attach 前会做依赖漂移检测 |
| `rqs` | 列出所有需求工作区的 git 分支和脏文件状态 |
| `req-create <name>` | 创建新需求工作区（worktree + 软链 + layout + profile）|
| `req-remove <name>` | 删除需求工作区（清理 worktree + session + profile）|
| `req-isolate <name> <proj>` | 把某个 worktree 的软链 node_modules 升级为独立安装 |
| `req-relink <name> <proj>` | 反向，丢弃独立 node_modules 切回软链共享 |

## 快速开始

### 1. 创建需求

```fish
req-create my-feature
```

**一条命令完成全部**：交互式选择项目和分支 → 自动创建 worktree → 软链 node_modules → 生成布局 → 直接进入 Zellij session。`--enter` 是默认行为，无需手动输入。

自动完成：
- 如果分支不存在，询问是否基于 master 创建（fetch + pull + create）
- 软链 `worktree/node_modules` → `repos/<proj>/node_modules`（主仓库无 `node_modules` 时先跑一次 `tnpm install --prefer-offline`）
- 生成 `.req/profiles/<名称>.json` 和 `.req/reqs/<名称>/layout.kdl`
- 创建 Zellij session 并自动 attach 进去

**三种调用方式**：

| 方式 | 示例 | 说明 |
|------|------|------|
| 完全交互 | `req-create my-feature` | 一步步选项目、选分支 |
| 混合模式 | `req-create my-feature product-page product-form:feat/b` | 传项目名，自动问缺失的分支 |
| 完全参数 | `req-create my-feature product-page:feat/a product-form:feat/b` | 所有信息命令行传完 |

右侧工具窗格默认启动 `qodercli`，可用 `--right-cmd=xxx` 覆盖：
```fish
req-create my-feature --right-cmd=fish
```

### 2. 进入/切换需求

```fish
zj my-feature
```

自动：
- 如果 session 已存在 → 直接 attach 进入
- 如果不存在 → 先创建（按 layout.kdl）然后 attach
- 如果当前在 Zellij 内 → 先 auto-detach 再 attach 到目标 session

在 Zellij session 内使用快捷键：
```
Alt-z → w → 选择目标 session
```

### 3. 查看状态

```fish
rqs
```

示例输出：
```
── my-feature ─
  product-page: feature/my-feature [dirty]
  product-form-components: feature/my-feature

── another-feature ──
  product-page: feature/another-feature
```

### 4. 依赖处理

默认情况下 worktree 的 `node_modules` 是软链到主仓库的，**所有 worktree 共享同一份依赖**。这意味着：

- 在 worktree 里直接 `tnpm install xxx` 会**污染主仓库**和其他 worktree
- 当某个分支真的要改依赖（加包、删包、改版本）时，先把它从软链升级为独立模式：

```fish
req-isolate my-feature product-page    # 独立化：本地 tnpm install
tnpm install some-pkg                   # 现在只影响这个 worktree
```

改完后如果想回到共享状态：

```fish
req-relink my-feature product-page      # 删本地 node_modules，重新软链
```

**自动检测**：每次 `zj <name>` attach 前，会比对 worktree 与主仓库的 `package-lock.json` / `yarn.lock` / `pnpm-lock.yaml`，发现不一致会提示。

### 5. 清理需求

```fish
req-remove my-feature
```

确认后自动清理：
- 删除 Zellij session
- 删除 git worktree（保留主仓库分支）
- 删除 `.req/profiles/` 和 `.req/reqs/` 下的元数据
- 删除 `reqs/my-feature/` 工作目录

## 目录结构

```
~/Documents/workspace/
├── repos/                      # 主仓库（git remote）
│   ├── product-page/
│   └── product-form-components/
├── reqs/                       # 需求工作区（git worktree）
│   ├── my-feature/
│   │   ├── product-page/       # worktree
│   │   └── product-form-components/
│   └── another-feature/
└── .req/
    ├── profiles/               # 需求元数据
    │   ├── my-feature.json
    │   └── another-feature.json
    └── reqs/                   # 布局文件
        ├── my-feature/
        └── another-feature/
```

## 布局文件

每个需求的 layout.kdl 预定义窗口布局（由 `req-create` 自动生成）：

```kdl
layout {
    pane size=1 borderless=true {
        plugin location="zellij:compact-bar"
    }
    pane split_direction="vertical" {
        pane size="40%" stacked=true {
            pane name="product-page" command="nvim" { cwd "..."; }
            pane name="product-form-components" command="nvim" { cwd "..."; }
            pane name="product-page-term" { cwd "..."; }
            pane name="product-form-components-term" { cwd "..."; }
        }
        pane name="tool" command="qodercli" { cwd "..."; }
    }
}
```

**布局结构**：
- 顶部 1 行：compact-bar（状态栏 + 快捷键提示）
- 左侧 `40%`：所有项目的 nvim 编辑器 + 对应终端，**统一 stacked**（用 zellij 的 stacked pane 切换快捷键在编辑器与终端间循环）
- 右侧 `60%`：`qodercli`（默认 AI 工具，可通过 `--right-cmd` 指定）

可以手动编辑 `.req/reqs/<name>/layout.kdl` 调整布局。

## 快捷键

Zellij 内可用快捷键（修改自默认 `Ctrl+o`）：

- `Alt-z` → 进入 Session 模式
- `Alt-z` → `w` → 选择 Zellij session（使用 session-manager 插件）

## 技术细节

- **PTY 包装**：使用 `~/.config/wezterm/zellij-spawn.py` 提供伪终端，解决 WezTerm 后台启动 zellij 时的 ENODEV 错误
- **ANSI 绕过**：session 存在性检查使用 `grep` 而非 fish `string match`，避免 ANSI 转义导致误判
- **PPID 检测**：追踪父进程链检测是否在 Zellij 内，比环境变量更可靠
- **node_modules 软链**：默认 `ln -s repos/<proj>/node_modules worktree/node_modules`，所有 worktree 共享磁盘；改依赖时通过 `req-isolate` 升级为独立目录

## 开发规范

### 分支策略

`req-create` 支持使用已有分支或自动创建新分支。分支名由你显式指定:

```fish
# 交互式输入分支名
req-create my-feature

# 或命令行直接传 <项目>:<分支> 对
req-create my-feature product-page:feature/xxx product-form-components:feature/yyy
```

**流程**:
1. 脚本检查目标分支是否存在(本地或 `remotes/origin/`)
2. 分支存在 → 在该分支上创建 worktree
3. 分支不存在 → 询问是否基于 master 创建:
   - `Y`(默认) → fetch + pull origin/master,然后 `git branch <新分支> master`
   - `n` → 跳过该项目
4. 如果主仓库正占用该分支,会先 stash 并 checkout 到 master,避免冲突

分支命名遵循团队规范,通常是 `feature/YYYYMMDD_工号_描述`(Aone 风格)。

### Git Worktree 设计

- **主仓库**(`repos/`)：保持在 `master` 分支,作为 worktree 的源
- **worktree**(`reqs/<需求名>/<项目>`)：每个需求在对应项目的 target 分支上创建独立工作区
- **分支隔离**：同一仓库的不同分支可以同时在不同 worktree 中 checkout,互不干扰
- **限制**：同一分支不能被多个 worktree 同时占用(Git 硬限制)

### node_modules 软链策略

**问题**：每个需求都需要完整的 `node_modules`，完整安装约 500MB-2GB；N 个 worktree 就是 N 份磁盘占用。

**解决**：默认软链共享主仓库的 `node_modules`

- 主仓库（`repos/<proj>/`）第一次使用时跑 `tnpm install --prefer-offline`
- worktree 的 `node_modules` 创建为指向主仓库的 symlink
- 启动时间秒级、磁盘 0 额外占用

**两种模式**：

| 模式 | 创建方式 | 适用场景 |
|------|---------|---------|
| 软链（默认） | `req-create` 自动 | 只改业务代码，不动 `package.json` |
| 独立 | `req-isolate <name> <proj>` | 加包/删包/改依赖版本 |

**典型流程**：

```fish
req-create my-feature                       # 软链，秒级
# 改业务代码... 直接开发
# 突然要加个新依赖：
req-isolate my-feature product-page          # 删软链，本地 tnpm install
tnpm install some-new-pkg                    # 只影响这个 worktree
# 用完后想节省磁盘：
req-relink my-feature product-page           # 切回软链
```

**自动检测**：`zj <name>` attach 前会对比 worktree 与主仓库的 lock 文件 hash，发现不一致会提示运行 `req-isolate` 或还原 lock。

**隐含要求**：worktree 和主仓库必须用**同一个 node 版本**，否则含原生模块（如 `node-sass` 的 C++ 扩展）会崩。推荐使用 `fnm` 配合 `.node-version` 文件锁定版本。

### Node 版本管理

- 用 `fnm` 管理多个 node 版本
- 项目根目录放 `.node-version` 文件(如 `20.19.0`)
- fish 启动时加载 `~/.config/fish/conf.d/node.fish`,进入含 `.node-version`/`.nvmrc` 的目录时自动切换

## 配置

### Fish aliases

`~/.config/fish/conf.d/req-aliases.fish` 定义所有命令。Fish 启动时自动加载。

### Zellij 配置

`~/.config/zellij/config.kdl` 中：
- `Ctrl o` → `Alt z`（Session 模式快捷键）

### 主仓库要求

`~/Documents/workspace/repos/` 下的仓库必须保持在 `master` 分支，所有开发在 `reqs/` 下的 worktree 进行。

## 新电脑初始化

在新电脑上部署这套 zj 工作流,按此顺序执行:

### 1. 部署 dotfiles

dotfiles 中部署的关键文件(部署后**无需手动调整**):

```
~/.config/
├── fish/conf.d/req-aliases.fish   # zj 工具主体 (使用 $HOME 动态路径)
├── fish/conf.d/zellij.fish        # zellij alias
├── wezterm/zellij-spawn.py        # Python PTY 包装器 (解决 WezTerm ENODEV)
└── zellij/
    ├── config.kdl                 # 完整 zellij 配置 (主题/插件/Alt-z 绑定)
    └── README.md                  # 本文件
```

把 dotfiles 仓库同步到新电脑的 `~/.config/` 即可,按你常用的方式:

```fish
# 示例:如果 dotfiles 仓库用 stow / chezmoi / 自己的 install.sh
cd ~/src/your-dotfiles-repo
./install.sh
```

### 2. 安装系统依赖

```fish
# 必需
brew install fish zellij python3 git

# 工作流常用(按需)
brew install ripgrep fzf neovim starship
```

`python3 --version` 应能成功执行;`~/.config/wezterm/zellij-spawn.py` 用到 `pty` 模块,这是标准库自带,不需额外安装。

### 3. 检查 fish 自动加载

fish 默认会自动 source `~/.config/fish/conf.d/` 下所有 `.fish` 文件,所以 `req-aliases.fish` 通常自动生效。

如不确定,验证:
```fish
functions zj  # 如果有输出,说明已加载
```

若未加载(少见),手动加到 `~/.config/fish/config.fish`:
```fish
source ~/.config/fish/conf.d/req-aliases.fish
```

### 4. 创建 workspace 目录结构

工具运行时会动态生成子目录,但首次使用前**建议先手动建一次框架**:

```fish
set -l WORKSPACE ~/Documents/workspace

mkdir -p $WORKSPACE/repos              # 主仓库集合 (git clone 到这里)
mkdir -p $WORKSPACE/reqs               # 需求工作区 (worktrees)
mkdir -p $WORKSPACE/.req/profiles      # 需求元数据 (profile.json)
mkdir -p $WORKSPACE/.req/reqs          # 布局文件 (layout.kdl,运行时自动生成)
```

主仓库放在 `repos/` 下,保持在 **master** 分支,业务开发在 `reqs/` 的 worktree 里进行。

### 5. 验证 zellij 配置

启动 zellij 后按 `Alt z`,左下角应显示 Session 模式快捷键:

```fish
zellij -s test-session
# 进入后按 Alt z
# 应看到:w (session-manager), c (configuration), p (plugin-manager), d (detach) 等
```

如果 `Alt z` 没反应,说明 dotfiles 部署失败,检查 `~/.config/zellij/config.kdl` 是否包含 `bind "Alt z"`。

### 6. 首次使用

**场景 A:全新需求**

```fish
# 先在 repos/ 下 clone 主仓库
cd ~/Documents/workspace/repos
git clone https://your-repo-url/some-project.git

# 创建需求工作区
req-create my-first-feature
# 交互式填写:项目(从 repos/ 中选)、分支
# 右侧工具默认 qodercli（可用 --right-cmd=xxx 更改）
# 完成后自动进入 Zellij session，无需额外命令
```

**场景 B:从已有 profile 恢复**

如果通过其他渠道(如从其他电脑迁移)拿到了 `~/Documents/workspace/.req/profiles/<name>.json` 和对应的 `repos/` 仓库:

```fish
zj existing-feature  # 自动重新生成 layout.kdl,创建 session,attach 进入
```

`layout.kdl` 是**派生文件**,每次 `zj` 启动时根据 profile.json 重新生成,路径会自动适配当前 `$HOME`,不需要手动改。

### 7. 故障排除

| 问题 | 排查 |
|------|------|
| `zj <name>` 报 "Could not attach" | 确保不在其他 zellij session 内,或先在当前 session 里 `Alt-z → d` detach |
| 右侧 qodercli 没自动启动 | `python3 -c "import pty"` 应成功;检查 `~/.config/wezterm/zellij-spawn.py` 存在；或尝试 `--right-cmd=fish` 切换为空白终端 |
| `Alt-z` 没反应 | 检查 `~/.config/zellij/config.kdl` 是否包含 `bind "Alt z"` |
| layout 加载失败 | 检查 profile.json 里 `rightPaneCommand` 字段是否存在；确认 `.req/reqs/<name>/layout.kdl` 存在且语法正确 |
| worktree 创建失败 | 通常是分支冲突(主仓库正在占用),先 `git stash` 并切回 master |

## 跨机器说明

| 内容 | 跨机器行为 |
|------|----------|
| `req-aliases.fish` / `zellij-spawn.py` | ✅ 使用 `$HOME` 动态路径,可直接同步 |
| `profile.json`(需求元数据) | ✅ 不含绝对路径,可跨机器同步 |
| `layout.kdl`(布局) | ⚠️ 派生文件,每次 `zj` 启动时重新生成,不同步 |
| zellij session 本身 | ❌ 仅本机存活(server 在本机 socket) |
| `~/Documents/workspace/repos/` | ❌ 不随 dotfiles 同步,新电脑需要重新 clone |
| `~/Documents/workspace/reqs/` | ❌ worktrees 仅本机有效 |

## 常见问题

### Q: 创建 session 时报 "Session 'req-xxx' not found"

可能是在 Zellij session 内运行了 `zj`。工具会自动检测并 detach，但如果检测失败，可以手动 `Alt-z → d` 退出后再试。

### Q: 创建需求时主仓库依赖没装

如果 `repos/<proj>/node_modules` 不存在，`req-create` 会先在主仓库跑一次 `tnpm install --prefer-offline`，之后所有 worktree 都软链复用。这一步只发生一次。

### Q: worktree 里直接 tnpm install 行不行？

软链模式下会污染主仓库以及所有其他 worktree。先 `req-isolate <name> <proj>` 升级为独立模式再装。改完想节省磁盘再 `req-relink`。

### Q: 两个需求用了同一分支

Git worktree 不允许两个 worktree 同时 checkout 同一分支。如果需要，可以在 `req-create` 时选择不同的分支名。

### Q: layout 没生效

检查 `.req/reqs/<name>/layout.kdl` 是否存在且语法正确。可以用 Zellij 直接测试：
```fish
zellij --session test action new-tab --layout ~/Documents/workspace/.req/reqs/my-feature/layout.kdl
```
