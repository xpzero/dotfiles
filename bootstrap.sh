#!/bin/bash

# 基础配置
REPO_URL="https://github.com/xpzero/dotfiles.git"
FILES_TO_SYMLINK=("dot")
OS=$(uname -s)

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

# 打印函数
info() { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
success() { printf "${GREEN}[SUCCESS]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; }

# 检测 Docker/Podman 等容器环境。Homebrew 不支持 Linux root 用户，因此 root 也走 apt 分支。
is_container() {
  [[ "$OS" == "Linux" && "$(id -u)" -eq 0 ]] && return 0
  [[ -f /.dockerenv || -f /run/.containerenv ]] && return 0
  [[ -r /proc/1/cgroup ]] && grep -qaE '(docker|containerd|kubepods|podman)' /proc/1/cgroup
}

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
    git -C "$(brew --repo)" remote set-url origin "$HOMEBREW_BREW_GIT_REMOTE"
  fi
}

# 安装 Linuxbrew 所需的系统依赖
install_linux_dependencies() {
  if [[ "$OS" != "Linux" ]]; then
    return
  fi

  if ! command -v apt-get &>/dev/null; then
    error "当前仅支持在 Ubuntu/Debian 上自动安装 Linuxbrew。"
    return 1
  fi

  info "正在安装 Linuxbrew 依赖..."
  sudo apt-get update && sudo apt-get install -y build-essential procps curl file git
}

# 加载 Homebrew 环境
load_brew() {
  local brew_path

  case "$OS" in
    Darwin)
      if [[ "$(uname -m)" == "arm64" ]]; then
        brew_path="/opt/homebrew/bin/brew"
      else
        brew_path="/usr/local/bin/brew"
      fi
      ;;
    Linux)
      brew_path="/home/linuxbrew/.linuxbrew/bin/brew"
      ;;
    *)
      error "不支持的操作系统: $OS"
      return 1
      ;;
  esac

  if [[ ! -x "$brew_path" ]]; then
    error "未找到 Homebrew: $brew_path"
    return 1
  fi

  eval "$("$brew_path" shellenv)"
}

# 1. 自动安装 Homebrew
install_brew() {
  # 提前设置禁止更新的环境变量
  export HOMEBREW_NO_AUTO_UPDATE=1

  if is_container; then
    info "检测到容器环境，跳过 Homebrew 安装。"
    return
  fi

  if ! command -v brew &>/dev/null; then
    info "Homebrew 未安装，正在通过镜像加速安装..."
    install_linux_dependencies || return 1

    local installer
    if ! installer=$(curl --http1.1 --retry 5 --retry-all-errors --retry-delay 2 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh); then
      error "无法下载 Homebrew 安装脚本。"
      return 1
    fi

    if ! /bin/bash -c "$installer"; then
      error "Homebrew 安装失败。"
      return 1
    fi

    load_brew || return 1

    # 安装完成后立即配置镜像
    set_brew_mirrors
  else
    info "Homebrew 已存在。"
    load_brew || return 1
    set_brew_mirrors
  fi
}

# 容器内使用系统包管理器安装基础命令行工具
setup_container_software() {
  if ! command -v apt-get &>/dev/null; then
    error "当前容器不是 Ubuntu/Debian，无法自动安装依赖。"
    return 1
  fi

  info "正在通过 apt 安装容器所需的基础工具..."
  apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y neovim fish git fzf ripgrep curl
}

# 2. 安装软件
setup_software() {
  if is_container; then
    setup_container_software
    return
  fi

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

# 3. 安装 Docker
setup_docker() {
  if is_container; then
    info "检测到容器环境，跳过 Docker 守护进程安装。"
    return
  fi

  case "$OS" in
    Darwin)
      if brew list --cask docker-desktop &>/dev/null; then
        info "Docker Desktop 已安装，跳过。"
      else
        info "正在安装 Docker Desktop..."
        brew install --cask docker-desktop
      fi
      ;;
    Linux)
      if command -v docker &>/dev/null; then
        info "Docker 已安装，跳过。"
        return
      fi

      if ! command -v apt-get &>/dev/null; then
        error "当前仅支持在 Ubuntu/Debian 上自动安装 Docker Engine。"
        return 1
      fi

      info "正在安装 Docker Engine..."
      sudo apt-get update && sudo apt-get install -y docker.io || return 1
      sudo usermod -aG docker "$USER" || return 1

      if command -v systemctl &>/dev/null; then
        sudo systemctl enable --now docker || info "Docker 服务未自动启动，请手动启动 docker 服务。"
      fi

      info "Docker 已安装。重新登录后可免 sudo 使用 docker。"
      ;;
    *)
      error "不支持的操作系统: $OS"
      return 1
      ;;
  esac
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

  for dir in "${FILES_TO_SYMLINK[@]}"; do
    if [[ ! -d "$dir" ]]; then continue; fi

    # 遍历目录下的所有文件（排除 . 和 ..）
    find "$dir" -maxdepth 1 -mindepth 1 -print0 | while IFS= read -r -d '' path; do
      local filename=$(basename "$path")
      local target="$HOME/.$filename"
      local source_dir
      source_dir=$(cd "$(dirname "$path")" && pwd -P)
      backup_and_link "$source_dir/$filename" "$target"
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

# 7. 设置 fish 为默认 shell
setup_fish_as_default() {
  if is_container; then
    info "检测到容器环境，跳过默认 Shell 修改。"
    return
  fi

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
  install_brew || exit 1
  setup_software || exit 1
  setup_docker || exit 1

  # 如果当前不在 dotfiles 目录，则初始化
  if [[ "$(basename "$(pwd)")" != "dotfiles" ]]; then
    initialize_repo
  fi

  install_dotfiles
  setup_fish_as_default

  success "所有配置已完成！"
}

main "$@"
