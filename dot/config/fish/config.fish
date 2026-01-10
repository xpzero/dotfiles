set -gx EDITOR n
set -gx PATH $PATH /opt/homebrew/bin
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
alias gst='git status'
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
alias gstc='git stash clear'
alias gstd='git stash drop'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gst='git status'
