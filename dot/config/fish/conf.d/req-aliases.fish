# 需求工作区快捷命令 (Fish 版本)
# Fish 自动加载 conf.d/ 下所有 .fish 文件

set -gx REQS_DIR "$HOME/Documents/workspace/reqs"
set -gx REPOS_DIR "$HOME/Documents/workspace/repos"

# rqs: 查看所有需求工作区状态（git 分支 + 脏标记）
function rqs --description "查看所有需求工作区状态"
    if not test -d "$REQS_DIR"; or test -z (ls -A "$REQS_DIR" 2>/dev/null)
        echo "当前没有活跃的需求工作区"
        return 1
    end

    for reqdir in "$REQS_DIR"/*/
        test -d "$reqdir"; or continue
        set -l name (basename "$reqdir")
        echo "── $name ──"
        for subdir in "$reqdir"*/
            test -d "$subdir"; or continue
            set -l proj (basename "$subdir")
            if test -e "$subdir/.git"
                set -l branch (git -C "$subdir" rev-parse --abbrev-ref HEAD 2>/dev/null | string trim)
                set -l dirty_count (git -C "$subdir" status --porcelain 2>/dev/null | wc -l | string trim)
                if test "$dirty_count" -gt 0
                    set -l flag " [dirty]"
                else
                    set -l flag ""
                end
                echo "  $proj: $branch$flag"
            else
                echo "  $proj: (非 git)"
            end
        end
        echo
    end
end

# req <name>: 切换到对应需求的 Zellij session（等价于 zj）
function req --description "切换到需求 Zellij session"
    zj $argv
end

# zj [name]: attach 或新建 Zellij session（自动加载 layout）
# 无参数时列出所有 req session
function zj --description "切换或创建需求 Zellij session"
    set -l name $argv[1]
    set -l reqdir "$REQS_DIR/$name"
    set -l session "req-$name"

    # 无参数：列出所有需求 session
    if test -z "$name"
        echo "需求 sessions:"
        zellij list-sessions 2>/dev/null | grep "^req-" | string replace /^/  /
        return 0
    end

    # 检测当前是否在 Zellij 客户端内（通过 PPID 链检测，比 zellij action 更可靠）
    # 原理：当前 shell 的父进程链上若有 zellij client，说明在 zellij 客户端内
    set -l in_zellij false
    set -l ppid $PPID
    for i in (seq 1 20)  # 最多向上追溯 20 层
        # 检查 ppid 是否有效（非空且大于 1）
        if test -z "$ppid"; or string match -qr '^\s*$' "$ppid"; or test "$ppid" -le 1
            break
        end
        
        set -l pname (ps -p $ppid -o command= 2>/dev/null)
        test -z "$pname"; and break
        
        if string match -rq '^zellij( .*)?$' "$pname"; or string match -rq '/zellij( .*)?$' "$pname"
            set in_zellij true
            break
        end
        
        # 获取父进程的 PID，如果获取失败则退出循环
        set ppid (ps -p $ppid -o ppid= 2>/dev/null | string trim)
        if test -z "$ppid"; or string match -qr '^\s*$' "$ppid"
            break
        end
    end

    # 如果在 Zellij 内 → 必须先 detach
    if test "$in_zellij" = "true"
        echo "检测到你在 Zellij session 内部，正在 detach..."
        zellij action detach >/dev/null 2>/dev/null
        sleep 0.5
    end

    # 目标 session 已存在 → 直接 attach
    if zellij list-sessions 2>/dev/null | grep -q "$session"
        echo "切换到已存在的 $session..."
        zellij attach "$session"
        return 0
    end

    # 目标 session 不存在 → 创建 session + 加载 layout
    if test -d "$reqdir"
        cd "$reqdir"
    end

    set -l layout "$HOME/Documents/workspace/.req/reqs/$name/layout.kdl"

    echo "创建 session: $session..."

    # 第一步：使用 Python pty spawn 提供伪终端（解决 WezTerm 后台启动 ENODEV 错误）
    # 同时传入 layout 路径，让 zellij 直接加载 layout，只创建单个 tab
    if test -f "$layout"
        python3 "$HOME/.config/wezterm/zellij-spawn.py" "$session" "$layout"
    else
        python3 "$HOME/.config/wezterm/zellij-spawn.py" "$session"
    end

    # 验证 session 是否真正创建成功（用 grep 直接匹配，绕过 ANSI 转义问题）
    if not zellij list-sessions 2>/dev/null | grep -q "$session"
        echo "创建 session 失败（Python PTY spawn 未能创建 session）"
        return 1
    end

    # 第二步：attach 到 session（需要真实 TTY，由用户在终端执行）
    echo "即将进入 $session..."
    sleep 0.5
    zellij attach "$session"
end

# req-create: 创建需求工作区（worktree + CoW node_modules + profile + layout + whistle）
function req-create --description "创建需求工作区"
    set -l name $argv[1]
    if test -z "$name"
        echo "用法: req-create <需求名>"
        return 1
    end

    set -l reqdir "$REQS_DIR/$name"
    set -l profile_path "$HOME/Documents/workspace/.req/profiles/$name.json"

    if test -d "$reqdir"
        echo "需求 '$name' 已存在: $reqdir"
        return 1
    end

    mkdir -p "$reqdir"
    mkdir -p "$HOME/Documents/workspace/.req/profiles"

    echo "=== 创建需求: $name ==="
    echo

    # 列出所有可用项目
    set -l repos
    for d in "$REPOS_DIR"/*/
        test -d "$d/.git"
        and set repos $repos (basename "$d")
    end

    if test (count $repos) -eq 0
        echo "repos/ 下没有找到任何 git 仓库"
        rmdir "$reqdir"
        return 1
    end

    echo "可用项目（编号选择，逗号分隔多个，直接回车跳过交互）："
    for i in (seq 1 (count $repos))
        echo "  $i) $repos[$i]"
    end
    echo

    # 支持直接传参模式：req-create <name> <proj1:branch1> <proj2:branch2> ...
    set -l projects
    if test (count $argv) -gt 1
        for i in (seq 2 (count $argv))
            set projects $projects $argv[$i]
        end
    else
        # 交互式模式
        read -p "选择项目 (如 1,2,3): " selected
        if test -z "$selected"
            echo "未选择项目"
            rmdir "$reqdir"
            return 1
        end

        set -l indices (string split ',' $selected)
        for idx in $indices
            set idx (string trim $idx)
            set -l proj_name $repos[$idx]
            if test -z "$proj_name"
                echo "无效的编号: $idx"
                continue
            end

            echo "项目: $proj_name"
            echo "  可用分支（最近）："
            git -C "$REPOS_DIR/$proj_name" branch -a --sort=-committerdate 2>/dev/null | head -5 | string replace /^/  "    "
            read -p "  输入分支名 (留空查看上方列表): " branch
            if test -z "$branch"
                echo "  分支不能为空，跳过 $proj_name"
                continue
            end
            set projects $projects "$proj_name:$branch"
        end
    end

    if test (count $projects) -eq 0
        echo "没有选择任何有效项目"
        rmdir "$reqdir"
        return 1
    end

    # 生成 profile JSON
    set -l created_projects
    set -l profile_entries

    for entry in $projects
        set -l parts (string split ':' $entry)
        set -l proj $parts[1]
        set -l branch $parts[2]
        set -l repo_dir "$REPOS_DIR/$proj"
        set -l wt_dir "$reqdir/$proj"

        echo "── 处理 $proj: $branch ──"

        # 检查仓库是否存在
        if not test -d "$repo_dir/.git"
            echo "  仓库不存在: $repo_dir，跳过"
            continue
        end

        # 检查分支是否存在
        set -l branch_exists (git -C "$repo_dir" branch -a 2>/dev/null | string match -r "(^\\*?\\s|remotes/origin/)$(string escape --style=regex $branch)")
        if test -z "$branch_exists"
            echo "  分支 '$branch' 在 $proj 中不存在，跳过"
            continue
        end

        # 检查主仓库是否正占用此分支
        set -l main_branch (git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null | string trim)
        if test "$main_branch" = "$branch"
            echo "  主仓库正在占用分支 '$branch'，尝试 stash + checkout master..."
            git -C "$repo_dir" stash push -m "auto-stash by req-create" 2>/dev/null
            git -C "$repo_dir" checkout master 2>&1 | string replace /^/  /
            if test $status -ne 0
                echo "  无法切换主仓库分支，跳过 $proj"
                continue
            end
        end

        # 创建 worktree
        echo "  创建 worktree..."
        git -C "$repo_dir" worktree add "$wt_dir" "$branch" 2>&1 | string replace /^/  /
        if test $status -ne 0
            echo "  worktree 创建失败，可能分支已被占用"
            continue
        end

        set created_projects $created_projects "$proj:$branch"

        # CoW 复制 node_modules
        if test -d "$repo_dir/node_modules"
            echo "  CoW 复制 node_modules（APFS 写时复制，几乎瞬时）..."
            cp -a "$repo_dir/node_modules" "$wt_dir/node_modules" 2>&1 | string replace /^/  /
            if test $status -eq 0
                echo "  node_modules 复制完成，开始 tnpm install..."
                cd "$wt_dir"; and tnpm install --prefer-offline 2>&1 | tail -3 | string replace /^/  /; cd -
            else
                echo "  node_modules 复制失败，执行完整 tnpm install..."
                cd "$wt_dir"; and tnpm install 2>&1 | tail -3 | string replace /^/  /; cd -
            end
        else
            echo "  主仓库无 node_modules，执行完整 tnpm install..."
            cd "$wt_dir"; and tnpm install 2>&1 | tail -3 | string replace /^/  /; cd -
        end

        # 拼接 profile JSON 条目
        if test (count $profile_entries) -eq 0
            set profile_entries "\"$proj\" : {\"branch\":\"$branch\",\"mode\":\"local\"}"
        else
            set profile_entries $profile_entries "\"$proj\" : {\"branch\":\"$branch\",\"mode\":\"local\"}"
        end

        echo "  ✓ $proj 完成"
        echo
    end

    if test (count $created_projects) -eq 0
        echo "所有项目均创建失败"
        rmdir "$reqdir"
        return 1
    end

    # 写入 profile JSON
    set -l profile_json '{ "name" : "'$name'", "projects" : { '"(string join ', ' $profile_entries)"' } }'
    echo "$profile_json" > "$profile_path"
    echo "✓ profile 已写入: $profile_path"

    # 生成 Zellij layout
    set -l layout_dir "$HOME/Documents/workspace/.req/reqs/$name"
    set -l layout_path "$layout_dir/layout.kdl"
    mkdir -p "$layout_dir"

    echo 'layout {' > "$layout_path"
    echo '    pane size=2 borderless=true {' >> "$layout_path"
    echo '        plugin location="zellij:compact-bar"' >> "$layout_path"
    echo '    }' >> "$layout_path"
    echo '    pane split_direction="horizontal" {' >> "$layout_path"
    for entry in $created_projects
        set -l parts (string split ':' $entry)
        set -l proj $parts[1]
        echo "        pane name=\"$proj\" command=\"nvim\" { cwd \"$reqdir/$proj\"; }" >> "$layout_path"
    end
    echo '    }' >> "$layout_path"
    echo '    pane size=30 {' >> "$layout_path"
    echo "        pane name=\"terminal\" { cwd \"$reqdir\"; }" >> "$layout_path"
    echo '    }' >> "$layout_path"
    echo '}' >> "$layout_path"
    echo "✓ layout 已写入: $layout_path"

    echo
    echo "✓ 需求 '$name' 工作区已创建完成"
    echo "  工作区: $reqdir"
    echo "  Profile: $profile_path"
    echo "  Layout: $layout_path"
    echo
    echo "下一步：在普通终端里执行"
    echo "    zj $name"
    echo
    echo "  ✓ 自动创建 Zellij session"
    echo "  ✓ 自动打开各项目的 nvim pane"
    echo "  ✓ 自动打开终端 pane 供你启 dev server"
    echo
    echo "创建后切换需求的方式："
    echo "  Alt-z → w → 选 req-$name"
    echo "  或在任意终端执行：zj $name"
end

# req-remove: 删除需求工作区
function req-remove --description "删除需求工作区"
    set -l name $argv[1]
    if test -z "$name"
        echo "用法: req-remove <需求名>"
        return 1
    end

    set -l reqdir "$REQS_DIR/$name"
    set -l profile_path "$HOME/Documents/workspace/.req/profiles/$name.json"
    set -l layout_dir "$HOME/Documents/workspace/.req/reqs/$name"
    set -l session "req-$name"

    if not test -d "$reqdir"
        echo "需求 '$name' 不存在"
        return 1
    end

    read -p "确认删除需求 '$name'？(y/N) " confirm
    if test "$confirm" != "y"; and test "$confirm" != "Y"
        echo "取消"
        return 0
    end

    echo "删除 Zellij session: $session"
    zellij kill-session "$session" 2>/dev/null

    # 逐个移除 worktree
    for wt in "$reqdir"/*/
        test -d "$wt"; or continue
        set -l proj (basename "$wt")
        set -l repo "$REPOS_DIR/$proj"
        if test -d "$repo/.git"
            echo "移除 worktree: $proj"
            git -C "$repo" worktree remove "$wt" --force 2>/dev/null
        end
    end

    # 删除需求目录
    if test -d "$reqdir"
        rm -rf "$reqdir"
    end

    # 删除 profile
    if test -f "$profile_path"
        rm -f "$profile_path"
        echo "已删除 profile: $profile_path"
    end

    # 删除 layout 目录
    if test -d "$layout_dir"
        rm -rf "$layout_dir"
    end

    echo "✓ 需求 '$name' 已清理"
end
