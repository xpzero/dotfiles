# 说明
仓库中包含
- alacritty
- tmux
- oh-my-zsh
- p10k
- zshrc
- nvim

# 安装脚本思路

1. 查找`dotfiles/dot/`下的所有文件(夹)
2. 如果上面的文件(夹)添加`$HOME/.`前缀后，可在家目录中找到，且不是软链接类型，则为其创建备份(原文件(夹)重命名为带有`.bak`的文件(夹))
3. 将`dotfiles/dot/`下的所有文件(夹)添加`$HOME/.`前缀，软链接到家(这里是`$HOME`)目录
4. 将`dotfiles/zsh/`下的所有文件夹根据其名字链接到`dotfiles/dot/oh-my-zsh/`下对应的目录中

# 使用

```sh
git clone https://github.com/xpzero/dotfiles.git --recurse-submodules

cd dotfiles && ./bootstrap.sh
```

##### 注意

`oh-my-zsh`、`p10k`等都是作为当前项目的子模块存在于repos目录中的。

普通克隆不会安装子模块，需要使用`--recurse-submodules`参数进行递归克隆。

子模块的repo地址都是github域名，网络问题需要考虑下。比如github域名的host代理。
