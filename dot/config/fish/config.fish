set -gx EDITOR nvim
set -gx PATH $PATH /opt/homebrew/bin
# 在文件末尾添加以下镜像配置（以清华源为例）
set -gx HOMEBREW_API_DOMAIN "mirrors.tuna.tsinghua.edu.cn"
set -gx HOMEBREW_BOTTLE_DOMAIN "mirrors.tuna.tsinghua.edu.cn"
set -gx HOMEBREW_BREW_GIT_REMOTE "mirrors.tuna.tsinghua.edu.cn"
set -gx HOMEBREW_CORE_GIT_REMOTE "mirrors.tuna.tsinghua.edu.cn"
set -gx HOMEBREW_PIP_INDEX_URL "pypi.tuna.tsinghua.edu.cn"
# 禁止 Homebrew 自动更新
set -gx HOMEBREW_NO_AUTO_UPDATE 1

if status is-interactive
    # 初始化 Starship 提示符
    starship init fish | source
    # --use-on-cd 参数：进入包含 .node-version 或 .nvmrc 的目录时自动切换 Node 版本
    fnm env --use-on-cd | source
end

# alias
alias pn="pnpm"
alias pnx="pnpx"
alias n="nvim"
# alias of git
alias ga='git add'
alias gaa='git add --all'
alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git checkout $(git_main_branch)'
alias gcl='git clone --recurse-submodules'
alias gcmsg='git commit --message'
alias gcp='git cherry-pick'
alias gd='git diff'
alias gdca='git diff --cached'
alias glg='git log --stat'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'
alias gloga='git log --oneline --decorate --graph --all'
alias gmom='git merge origin/$(git_main_branch)'
alias gl='git pull'
alias gp='git push'
alias gpf='git push --force'
alias grhh='git reset --hard'
alias grs='git restore'
alias gsta='git stash save'
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gst='git status'

# opencode
fish_add_path "$HOME/.opencode/bin"
