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
  export HOMEBREW_API_DOMAIN="mirrors.tuna.tsinghua.edu.cn"
  export HOMEBREW_BREW_GIT_REMOTE="mirrors.tuna.tsinghua.edu.cn"
  export HOMEBREW_CORE_GIT_REMOTE="mirrors.tuna.tsinghua.edu.cn"
  export HOMEBREW_BOTTLE_DOMAIN="mirrors.tuna.tsinghua.edu.cn"

  # 2. 如果已经安装过，同步重置远程仓库地址 (可选)
  if command -v brew &>/dev/null; then
    git -C "$(brew --repo)" remote set-url origin mirrors.tuna.tsinghua.edu.cn
  fi
}

# 1. 自动安装 Homebrew
install_brew() {
  # 提前设置禁止更新的环境变量
  export HOMEBREW_NO_AUTO_UPDATE=1

  if ! command -v brew &>/dev/null; then
    info "Homebrew 未安装，正在通过镜像加速安装..."

    # 使用国内镜像脚本安装（如：中科大提供的安装工具或清华大学提供的脚本）
    /bin/bash -c "$(curl -fsSL raw.githubusercontent.com)"

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
  local apps=(neovim wezterm fish starship fnm git fzf ripgrep)
  for app in "${apps[@]}"; do
    if ! brew list "$app" &>/dev/null; then
      brew install "$app"
    else
      info "$app 已安装，跳过。"
    fi
  done
}

# 3. 备份与符号链接逻辑
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

# 4. 执行安装 Dotfiles
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

# 5. 初始化仓库 (如果需要)
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

# 6. 设置 fish 为默认 shell
setup_fish_as_default() {
  local fish_path
  fish_path=$(which fish)

  # 1. 检查是否已经是默认 shell
  if [[ "$SHELL" == "$fish_path" ]]; then
    info "Fish 已经是默认 shell。"
    return
  fi

  # 2. 将 fish 路径添加到 /etc/shells (如果不存在)
  # 这步很重要，否则 chsh 会因为 "non-standard shell" 报错
  if ! grep -q "$fish_path" /etc/shells; then
    info "将 $fish_path 添加到 /etc/shells..."
    echo "$fish_path" | sudo tee -a /etc/shells
  fi

  # 3. 切换默认 shell
  info "正在切换默认 shell 到 fish..."
  if chsh -s "$fish_path"; then
    success "默认 shell 已切换为 fish。请重启终端或重新登录以生效。"
  else
    error "切换默认 shell 失败，请尝试手动执行: chsh -s $fish_path"
  fi
}

# --- 执行流程 ---

main() {
  # 确保网络环境能连接 GitHub
  install_brew
  setup_software

  # 如果当前不在 dotfiles 目录，则初始化
  if [[ "$(basename "$(pwd)")" != "dotfiles" ]]; then
    initialize_repo
  fi

  install_dotfiles
  setup_fish_as_default

  success "所有配置已完成！"
}

main "$@"
