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
        zellij list-sessions 2>/dev/null | grep "^req-" | string replace -r '^' '  '
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

    # attach 前检测依赖漂移
    if test -d "$reqdir"
        __req_check_deps_drift "$reqdir"
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

# req-create: 创建需求工作区 (worktree + profile + layout)
#
# 用法:
#   交互模式:  req-create <需求名> [--right-cmd=xxx] [--no-enter]
#   参数模式:  req-create <需求名> <proj1:branch1> [proj2:branch2] ... [--right-cmd=xxx] [--no-enter]
#
#   --right-cmd: 右侧窗格命令 (默认 qodercli)
#   --no-enter:  创建后不自动进入 session (默认会自动进入)
#
# 布局结构:
#   顶部 compact-bar (5%)
#   左侧 70%:
#     上方: 各项目的 nvim 编辑窗格 (横向排列)
#     下方: 各项目的 dev server (stacked 切换)
#   右侧 30%: tool pane (qodercli 或指定命令)
function req-create --description "创建需求工作区"
    # 解析标志参数 (--enter 默认 true，可用 --no-enter 禁用)
    set -l enter true
    set -l right_cmd ""
    set -l args

    set -l i 1
    while test $i -le (count $argv)
        set -l arg $argv[$i]
        if test "$arg" = "--no-enter"
            set enter false
        else if string match -q -- '--right-cmd=*' "$arg"
            set right_cmd (string split '=' "$arg")[2]
        else
            set args $args "$arg"
        end
        set i (math $i + 1)
    end
    # 默认右侧命令
    if test -z "$right_cmd"
        set right_cmd "qodercli"
    end

    # 取需求名
    set -l name $args[1]
    if test -z "$name"
        echo "用法:"
        echo "  交互模式: req-create <需求名> [--right-cmd=xxx] [--no-enter]"
        echo "  参数模式: req-create <需求名> <proj1:branch1> [proj2:branch2] ... [--right-cmd=xxx] [--no-enter]"
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

    # 列出可用项目
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

    # 清理所有主仓库的失效 worktree 元数据（防止之前残留导致"分支已被占用"）
    for repo in $repos
        git -C "$REPOS_DIR/$repo" worktree prune 2>/dev/null
    end

    # === 选择项目: 参数模式 or 交互模式 ===
    set -l projects
    if test (count $args) -gt 1
        # 参数模式: 从命令行获取项目:分支
        set -l i 2
        while test $i -le (count $args)
            set projects $projects $args[$i]
            set i (math $i + 1)
        end
    else
        # 交互模式
        echo "可用项目（编号选择，逗号分隔多个）："
        for i in (seq 1 (count $repos))
            echo "  $i) $repos[$i]"
        end
        echo
        set select_text ""
        echo -n "选择项目 (如 1,2,3): "; read select_text
        if test -z "$select_text"
            echo "未选择项目"
            rmdir "$reqdir"
            return 1
        end
        set selected "$select_text"

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
            git -C "$REPOS_DIR/$proj_name" branch -a --sort=-committerdate 2>/dev/null | head -5 | sed 's/^/    /'
            set branch ""
            echo -n "  输入分支名 (留空查看上方列表): "; read branch_text
            set branch "$branch_text"
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

        # 如果没有指定分支（无冒号或冒号后为空），交互询问
        if test -z "$branch"
            echo "── 处理 $proj: 分支未指定 ──"
            set branch ""
            echo -n "  请输入分支名: "; read branch_text
            set branch "$branch_text"
            if test -z "$branch"
                echo "  分支不能为空，跳过 $proj"
                continue
            end
        end

        set -l repo_dir "$REPOS_DIR/$proj"
        set -l wt_dir "$reqdir/$proj"

        echo "── 处理 $proj: $branch ─"

        # 检查仓库是否存在
        if not test -d "$repo_dir/.git"
            echo "  仓库不存在: $repo_dir，跳过"
            continue
        end

        # 检查分支是否存在
        set -l branch_exists (git -C "$repo_dir" branch -a 2>/dev/null | string match -r "(^\\*?\\s|remotes/origin/)$(string escape --style=regex $branch)")
        if test -z "$branch_exists"
            echo "  分支 '$branch' 在 $proj 中不存在"
            set create_branch ""
            echo -n "是否基于 master 创建? [Y/n]: "; read create_branch
            if test "$create_branch" = "n"; or test "$create_branch" = "N"
                echo "跳过 $proj"
                continue
            end

            # fetch origin master
            echo "  拉取 origin/master..."
            set -l fetch_output (git -C "$repo_dir" fetch origin master 2>&1)
            set -l fetch_status $status
            echo "$fetch_output" | string replace -r '^' '  '
            if test $fetch_status -ne 0
                echo "fetch 失败，跳过 $proj"
                continue
            end

            # 如果当前不在 master，先 stash 并 checkout
            set -l current_branch (git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null | string trim)
            if test "$current_branch" != "master"
                echo "  切换到 master..."
                git -C "$repo_dir" stash push -m "auto-stash by req-create" 2>/dev/null
                set -l checkout_output (git -C "$repo_dir" checkout master 2>&1)
                set -l checkout_status $status
                echo "$checkout_output" | string replace -r '^' '  '
                if test $checkout_status -ne 0
                    echo "切换到 master 失败，跳过 $proj"
                    continue
                end
            end

            # pull origin master to update local master
            echo "  更新 master 到最新..."
            git -C "$repo_dir" pull origin master 2>&1 | string replace -r '^' '  '

            # 创建新分支
            echo "  创建新分支: $branch"
            set -l branch_output (git -C "$repo_dir" branch "$branch" 2>&1)
            set -l branch_status $status
            echo "$branch_output" | string replace -r '^' '  '
            if test $branch_status -ne 0
                echo "创建分支失败，跳过 $proj"
                continue
            end
        end

        # 检查主仓库是否正占用此分支
        set -l main_branch (git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null | string trim)
        if test "$main_branch" = "$branch"
            echo "  主仓库正在占用分支 '$branch'，尝试 stash + checkout master..."
            git -C "$repo_dir" stash push -m "auto-stash by req-create" 2>/dev/null
            git -C "$repo_dir" checkout master 2>&1 | string replace -r '^' '  '
            if test $status -ne 0
                echo "  无法切换主仓库分支，跳过 $proj"
                continue
            end
        end

        # 创建 worktree
        echo "  创建 worktree..."
        set -l worktree_output (git -C "$repo_dir" worktree add "$wt_dir" "$branch" 2>&1)
        set -l worktree_status $status
        echo "$worktree_output" | string replace -r '^' '  '
        if test $worktree_status -ne 0
            echo "  worktree 创建失败，可能分支已被占用"
            continue
        end

        set created_projects $created_projects "$proj:$branch"

        # 依赖处理：软链到主仓库 node_modules
        # 优点：秒级完成、0 磁盘开销；缺点：worktree 内不能改依赖（要改请用 req-isolate）
        echo "  链接依赖..."
        __req_link_node_modules "$repo_dir" "$wt_dir"

        # 拼接 profile JSON 条目
        if test (count $profile_entries) -eq 0
            set profile_entries "\"$proj\" : {\"branch\":\"$branch\",\"mode\":\"link\"}"
        else
            set profile_entries $profile_entries "\"$proj\" : {\"branch\":\"$branch\",\"mode\":\"link\"}"
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
    set -l profile_json '{ "name" : "'$name'", "rightPaneCommand" : "'$right_cmd'", "projects" : { '"(string join ', ' $profile_entries)"' } }'
    echo "$profile_json" > "$profile_path"
    echo "✓ profile 已写入: $profile_path"

    # 生成 Zellij layout
    # 结构:
    #   顶部 compact-bar (5%)
    #   左侧 40%: 所有项目的 nvim + 终端，统一 stacked
    #   右侧 60%: tool pane (qodercli)
    set -l layout_dir "$HOME/Documents/workspace/.req/reqs/$name"
    set -l layout_path "$layout_dir/layout.kdl"
    mkdir -p "$layout_dir"

    echo 'layout {' > "$layout_path"
    echo '    pane size=1 borderless=true {' >> "$layout_path"
    echo '        plugin location="zellij:compact-bar"' >> "$layout_path"
    echo '    }' >> "$layout_path"
    echo '    pane split_direction="vertical" {' >> "$layout_path"
    # 左侧 40% - 所有 pane 统一 stacked
    echo '        pane size="40%" stacked=true {' >> "$layout_path"
    for entry in $created_projects
        set -l parts (string split ':' $entry)
        set -l proj $parts[1]
        echo "            pane name=\"$proj\" command=\"nvim\" { cwd \"$reqdir/$proj\"; }" >> "$layout_path"
    end
    for entry in $created_projects
        set -l parts (string split ':' $entry)
        set -l proj $parts[1]
        echo "            pane name=\"$proj-term\" { cwd \"$reqdir/$proj\"; }" >> "$layout_path"
    end
    echo '        }' >> "$layout_path"
    # 右侧 30% 工具 pane
    echo '        pane name="tool" command="'$right_cmd'" { cwd "'$reqdir'"; }' >> "$layout_path"
    echo '    }' >> "$layout_path"
    echo '}' >> "$layout_path"
    echo "✓ layout 已写入: $layout_path"

    echo
    echo "✓ 需求 '$name' 工作区已创建完成"
    echo "  工作区: $reqdir"
    echo "  Profile: $profile_path"
    echo "  Layout: $layout_path"

    # 如果指定了 --enter，自动进入 session
    if test "$enter" = "true"
        echo
        echo "正在进入 session '$name'..."
        zj $name
    else
        echo
        echo "下一步：zj $name"
    end
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

    echo -n "确认删除需求 '$name'？(y/N) "; read confirm
    echo
    if test "$confirm" != "y"; and test "$confirm" != "Y"
        echo "取消"
        return 0
    end

    echo "删除 Zellij session: $session"
    zellij kill-session "$session" 2>/dev/null
    zellij delete-session "$session" --force 2>/dev/null

    # 逐个移除 worktree
    for wt in "$reqdir"/*/
        test -d "$wt"; or continue
        set -l proj (basename "$wt")
        set -l repo "$REPOS_DIR/$proj"
        if test -d "$repo/.git"
            echo "移除 worktree: $proj"
            git -C "$repo" worktree remove "$wt" --force 2>/dev/null
            git -C "$repo" worktree prune 2>/dev/null
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

# === 内部 helper：把 worktree 的 node_modules 软链到主仓库 ===
# 参数: $repo_dir(主仓库) $wt_dir(worktree 目录)
function __req_link_node_modules --description "软链 worktree 的 node_modules 到主仓库"
    set -l repo_dir $argv[1]
    set -l wt_dir $argv[2]

    # 主仓库无 node_modules → 先安装
    if not test -d "$repo_dir/node_modules"
        echo "    主仓库无 node_modules，先安装..."
        pushd "$repo_dir" >/dev/null
        tnpm install --prefer-offline 2>&1 | tail -3 | string replace -r '^' '    '
        popd >/dev/null
    end

    # worktree 内若已有实体 node_modules，跳过避免覆盖
    if test -d "$wt_dir/node_modules"; and not test -L "$wt_dir/node_modules"
        echo "    已存在实体 node_modules，跳过软链"
        return 0
    end

    # 移除旧软链（若有）
    test -L "$wt_dir/node_modules"; and rm "$wt_dir/node_modules"

    ln -s "$repo_dir/node_modules" "$wt_dir/node_modules"
    echo "    ✓ 软链: $wt_dir/node_modules -> $repo_dir/node_modules"
end

# === 内部 helper：检测 worktree 依赖是否相对主仓库漂移 ===
# 参数: $reqdir
function __req_check_deps_drift --description "检测 worktree 的 lock 是否与主仓库不同"
    set -l reqdir $argv[1]
    set -l drifted

    for wt in "$reqdir"/*/
        test -d "$wt"; or continue
        set -l proj (basename "$wt")
        set -l repo "$REPOS_DIR/$proj"
        test -d "$repo/.git"; or continue

        # 软链模式无需检测（共享 node_modules）
        if test -L "$wt/node_modules"
            for lock in package-lock.json yarn.lock pnpm-lock.yaml
                if test -f "$wt/$lock"; and test -f "$repo/$lock"
                    set -l h1 (shasum "$wt/$lock" 2>/dev/null | string split ' ')[1]
                    set -l h2 (shasum "$repo/$lock" 2>/dev/null | string split ' ')[1]
                    if test "$h1" != "$h2"
                        set drifted $drifted "$proj($lock)"
                    end
                end
            end
        end
    end

    if test (count $drifted) -gt 0
        echo
        echo "⚠ 以下 worktree 的 lock 与主仓库不一致，依赖可能错位："
        for d in $drifted
            echo "    - $d"
        end
        echo "  处理方式："
        echo "    req-isolate <需求名> <项目名>   # 升级为独立 node_modules"
        echo "    git checkout package-lock.json  # 放弃 worktree 内的 lock 修改"
        echo
    end
end

# === req-isolate: 把 worktree 从软链升级为独立 node_modules ===
function req-isolate --description "把 worktree 的 node_modules 切换为独立安装"
    set -l name $argv[1]
    set -l proj $argv[2]
    if test -z "$name"; or test -z "$proj"
        echo "用法: req-isolate <需求名> <项目名>"
        return 1
    end

    set -l wt_dir "$REQS_DIR/$name/$proj"
    if not test -d "$wt_dir"
        echo "worktree 不存在: $wt_dir"
        return 1
    end

    # 已经是实体目录则跳过
    if test -d "$wt_dir/node_modules"; and not test -L "$wt_dir/node_modules"
        echo "$proj 已经是独立模式，无需 isolate"
        return 0
    end

    # 移除软链
    if test -L "$wt_dir/node_modules"
        rm "$wt_dir/node_modules"
        echo "已移除软链: $wt_dir/node_modules"
    end

    echo "在 $wt_dir 执行 tnpm install..."
    pushd "$wt_dir" >/dev/null
    tnpm install --prefer-offline
    set -l rc $status
    popd >/dev/null

    if test $rc -eq 0
        echo "✓ $proj 已切换为独立模式"
    else
        echo "✗ tnpm install 失败 (rc=$rc)"
        return $rc
    end
end

# === req-relink: 把独立 node_modules 切回软链 ===
function req-relink --description "把 worktree 的 node_modules 切回软链共享"
    set -l name $argv[1]
    set -l proj $argv[2]
    if test -z "$name"; or test -z "$proj"
        echo "用法: req-relink <需求名> <项目名>"
        return 1
    end

    set -l wt_dir "$REQS_DIR/$name/$proj"
    set -l repo_dir "$REPOS_DIR/$proj"
    if not test -d "$wt_dir"
        echo "worktree 不存在: $wt_dir"
        return 1
    end
    if not test -d "$repo_dir/.git"
        echo "主仓库不存在: $repo_dir"
        return 1
    end

    # 已经是软链则跳过
    if test -L "$wt_dir/node_modules"
        echo "$proj 已经是软链模式，无需 relink"
        return 0
    end

    if test -d "$wt_dir/node_modules"
        echo -n "将删除 $wt_dir/node_modules 切回软链，确认？(y/N) "; read confirm
        if test "$confirm" != "y"; and test "$confirm" != "Y"
            echo "取消"
            return 0
        end
        rm -rf "$wt_dir/node_modules"
    end

    __req_link_node_modules "$repo_dir" "$wt_dir"
end
