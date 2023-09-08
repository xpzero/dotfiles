# 说明
仓库中包含
- alacritty
- tmux
- oh-my-zsh
- p10k
- zshrc
- nvim

# 使用

`oh-my-zsh`、`p10k`等都是当前项目`git`子模块，可以减少仓库容量。

普通克隆不会安装子模块，需要递归克隆。

```sh
git clone https://github.com/xpzero/dotfiles.git --recurse-submodules
```

##### 注意
子模块的repo地址都是github域名，网络问题需要考虑下。比如github域名的host代理。
