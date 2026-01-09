## 效果

### LazyVim

![LazyVim](./assets/img/LazyVim.png)

### wezterm

![wezterm](./assets/img/wezterm.png)

## 说明

仓库中包含

- alacritty、wezterm
  - 终端软件，功能简单，速度快，跨平台可用。
  - 二者都是rust写的。alacritty更新慢
- oh-my-zsh
  - shell工具，让终端命令使用起来更方便
- powerlevel10k(p10k)
  - shell主题
- zshrc
  - shell配置，比如命令别名等
- nvim
  - `NeoVim`。比`Vim`功能更强大

## 安装步骤

### 安装`assets/font`中的字体

配合`startship`显示图标字符

### 安装`NeoVim`、`wezterm`、`starship`

需要去官网安装对应的软件。如是`Mac`系统，使用包管理工具`brew`，下载安装即可

`wezterm`最好下载安装包，使用`brew`安装，可能有网络问题

### 安装配置文件

- 拉取本仓库代码
- 执行安装脚本

```sh
git clone https://github.com/xpzero/dotfiles.git && cd dotfiles && ./bootstrap.sh
```

#### 脚本代码思路

1. 查找`dotfiles/dot/`下的所有文件(夹)
2. 如果上面的文件(夹)添加`$HOME/.`前缀后，可在家目录中找到，且不是软链接类型，则为其创建备份(原文件(夹)重命名为带有`.bak`的文件(夹))
3. 将`dotfiles/dot/`下的所有文件(夹)添加`$HOME/.`前缀，软链接到家(这里是`$HOME`)目录
4. 将`dotfiles/zsh/`下的所有文件夹根据其名字链接到`dotfiles/dot/oh-my-zsh/`下对应的目录中
