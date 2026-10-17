#!/bin/bash

# 基础配置
REPO_URL="https://github.com/xpzero/dotfiles.git"
FILES_TO_SYMLINK=("dot")

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 打印函数
info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

# brew镜像
set_brew_mirrors() {
  info "正在配置 Homebrew 国内镜像源..."

  # 1. 设置环境变量，加速 API 和 Bottles 下载
  export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
  export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
  export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"

  # 2. 如果已经安装过，同步重置远程仓库地址 (可选)
  if command -v brew &>/dev/null; then
    git -C "$(brew --repo)" remote set-url origin "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
  fi
}

# 1. 自动安装 Homebrew
install_brew() {
  # 提前设置禁止更新的环境变量
  export HOMEBREW_NO_AUTO_UPDATE=1

  if ! command -v brew &>/dev/null; then
    info "Homebrew 未安装，正在通过镜像加速安装..."

    # 通过官方脚本安装，镜像加速由上方导出的 HOMEBREW_* 环境变量提供
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # 激活环境变量
    if [[ "$(uname -m)" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi

    # 安装完成后立即配置镜像
    set_brew_mirrors
  else
    info "Homebrew 已存在。"
    set_brew_mirrors
  fi
}

# 2. 安装软件
setup_software() {
  info "正在通过 Homebrew 安装软件..."
  local apps=(neovim wezterm fnm git fzf ripgrep herdr uv python3 imagemagick)
  for app in "${apps[@]}"; do
    if ! brew list "$app" &>/dev/null; then
      brew install "$app"
    else
      info "$app 已安装，跳过。"
    fi
  done
}

# 3. 安装 Python 工具链与 Jupyter 环境（Neovim notebook 支持）
setup_python_env() {
  # jupytext：jupytext.nvim 依赖的 ipynb 转换 CLI
  if ! command -v jupytext &>/dev/null; then
    info "通过 uv 安装 jupytext..."
    uv tool install jupytext
  else
    info "jupytext 已安装，跳过。"
  fi

  # Neovim 专用 Jupyter venv：molten 远程插件与内核的运行环境
  # 注意：Homebrew 升级 Python 后 venv 可能损坏，重跑本脚本即可重建
  local venv="$HOME/.local/share/jupyter/venvs/neovim-python"
  if [[ ! -x "$venv/bin/python" ]]; then
    info "创建 Neovim Jupyter 专用 venv..."
    mkdir -p "$(dirname "$venv")"
    python3 -m venv "$venv"
  fi
  info "安装 venv 依赖 (pynvim/jupyter_client/ipykernel 等)..."
  "$venv/bin/pip" install -q --upgrade pip
  "$venv/bin/pip" install -q pynvim jupyter_client ipykernel nbformat pillow pyperclip

  # 注册 kernelspec（名字与 venv 目录名一致，molten 据此自动匹配内核）
  local kernel_dir="$HOME/Library/Jupyter/kernels/neovim-python"
  if [[ ! -d "$kernel_dir" ]]; then
    "$venv/bin/python" -m ipykernel install --user --name neovim-python --display-name "Python (neovim)"
    success "已注册 kernelspec: Python (neovim)"
  else
    info "kernelspec neovim-python 已存在，跳过。"
  fi
}

# 4. 备份与符号链接逻辑
backup_and_link() {
  local src=$1
  local dest=$2

  # 如果目标已存在且不是软链接，执行备份
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    info "备份现有文件: $dest -> $dest.bak"
    mv "$dest" "$dest.bak"
  fi

  # 删除旧链接或文件并创建新链接
  rm -rf "$dest"
  ln -sf "$src" "$dest"
  success "已链接: $dest"
}

# 5. 执行安装 Dotfiles
install_dotfiles() {
  info "开始安装 Dotfiles..."

  # 确保在仓库根目录执行
  local current_dir=$(pwd)

  for dir in "${FILES_TO_SYMLINK[@]}"; do
    if [[ ! -d "$dir" ]]; then continue; fi

    # 遍历目录下的所有文件（排除 . 和 ..）
    find "$dir" -maxdepth 1 -mindepth 1 | while read -r path; do
      local filename=$(basename "$path")
      local target="$HOME/.$filename"
      backup_and_link "$(realpath "$path")" "$target"
    done
  done
}

# 6. 初始化仓库 (如果需要)
# 获取远程分支并选择
choose_branch_and_clone() {
  local url=$1
  info "正在获取远程分支列表..."

  # 获取远程分支名（过滤掉 HEAD）
  # 使用 git ls-remote --heads 获取最准确的远程分支列表
  local branches=$(git ls-remote --heads "$url" | awk -F'refs/heads/' '{print $2}')

  if [[ -z "$branches" ]]; then
    error "无法获取分支列表，请检查网络或 URL。"
    exit 1
  fi

  # 将分支转为数组
  local branch_array=($branches)

  echo "------------------------------------------------"
  echo "请选择要克隆的分支:"
  for i in "${!branch_array[@]}"; do
    printf "%d) %s\n" $((i + 1)) "${branch_array[$i]}"
  done
  echo "------------------------------------------------"

  local choice
  while true; do
    read -p "输入数字选择 (默认 1): " choice
    choice=${choice:-1} # 默认为第一个分支

    if [[ "$choice" -gt 0 && "$choice" -le "${#branch_array[@]}" ]]; then
      local selected_branch="${branch_array[$((choice - 1))]}"
      info "已选择分支: $selected_branch"

      # 执行克隆
      git clone -b "$selected_branch" --recurse-submodules "$url" dotfiles
      return $?
    else
      echo "无效选项，请重新输入。"
    fi
  done
}

# 修改后的初始化函数
initialize_repo() {
  if [[ ! -d "dotfiles" ]]; then
    info "-------------------- 开始初始化仓库 --------------------"
    choose_branch_and_clone "$REPO_URL"

    if [ "$?" -eq 0 ]; then
      success "仓库克隆成功。"
      cd "dotfiles" || exit
    else
      error "仓库克隆失败，请重试。"
      exit 1
    fi
  else
    info "检测到 dotfiles 目录已存在，跳过克隆。"
    cd "dotfiles" || exit
  fi
}

# 7. 设置 zsh 为默认 shell（/bin/zsh 是系统自带，无需写入 /etc/shells）
setup_zsh_as_default() {
  if [[ "$SHELL" == "/bin/zsh" ]]; then
    info "zsh 已经是默认 shell。"
    return
  fi

  info "正在切换默认 shell 到 zsh..."
  if chsh -s /bin/zsh; then
    success "默认 shell 已切换为 zsh。请重启终端或重新登录以生效。"
  else
    error "切换默认 shell 失败，请尝试手动执行: chsh -s /bin/zsh"
  fi
}

# 8. 初始化 git 子模块（oh-my-zsh、powerlevel10k 等）
setup_submodules() {
  info "正在初始化 git 子模块（oh-my-zsh / powerlevel10k）..."
  git submodule update --init --recursive
}

# --- 执行流程 ---

main() {
  # 确保网络环境能连接 GitHub
  install_brew
  setup_software
  setup_python_env

  # 如果当前不在 dotfiles 目录，则初始化
  if [[ "$(basename "$(pwd)")" != "dotfiles" ]]; then
    initialize_repo
  fi

  install_dotfiles
  setup_submodules
  setup_zsh_as_default

  success "所有配置已完成！"
}

main "$@"
