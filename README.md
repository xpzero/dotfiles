# 说明
仓库中包含
- alacritty
- tmux
- oh-my-zsh
- p10k
- zshrc
- nvim

# 使用

```sh
git clone https://github.com/xpzero/dotfiles.git --recurse-submodules

cd dotfiles && ./bootstrap.sh
```

##### 注意

`oh-my-zsh`、`p10k`等都是作为当前项目的子模块存在于repos目录中的。

普通克隆不会安装子模块，需要使用`--recurse-submodules`参数进行递归克隆。

子模块的repo地址都是github域名，网络问题需要考虑下。比如github域名的host代理。
