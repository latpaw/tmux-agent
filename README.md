# Claude Code Tmux Hooks

在 tmux 多窗口环境下增强 Claude Code 的会话状态可视化。通过 Claude Code 的 hooks 机制，在 tmux 窗口标签上实时反映每个会话的状态：等待授权、正在工作、已完成。

仓库里还附带一个独立工具 `wtmux`：把一个仓库的每个 git worktree 各开一个 tmux 窗口，窗口名带上分支和该 worktree 正在监听的端口——多窗口跑 agent 时用它一键铺开。

## 解决什么问题

同时在多个 tmux 窗口中运行 Claude Code 时，很难判断哪个窗口需要你操作、哪个已经完成。这套 hooks 用颜色和文字标记解决这个问题：

- **黄底黑字** — 需要授权，等你操作
- **绿底白字 + "DONE"** — Claude 已完成回答
- **默认样式** — 正在工作中

## 脚本说明

| 脚本 | 触发事件 | 作用 |
|------|---------|------|
| `tmux-session-start.sh` | Claude Code `SessionStart` | 记录当前窗口信息，供后续脚本定位 |
| `tmux-stop.sh` | Claude Code `Stop` | 窗口名加 " DONE"，设绿底白字 |
| `tmux-permission-request.sh` | Claude Code `PermissionRequest` | 设黄底黑字，提醒需要授权 |
| `tmux-clear-permission-style.sh` | Claude Code `PostToolUse` / `PermissionDenied` | 授权或拒绝后清除黄色 |
| `tmux-restore-name.sh` | Claude Code `UserPromptSubmit` | 用户发送消息时恢复窗口名称 |
| `tmux-focus-strip-done.sh` | tmux `session-window-changed` | 切到窗口时自动移除 DONE |
| `agent-tmux-wrapper.sh` | 手动运行 | 让非 Claude Code 的 agent 也能使用状态提示 |
| `wtmux` | 手动运行 | 每个 git worktree 开一个 tmux 窗口，窗口名带分支和监听端口 |

## 安装

### 1. 克隆到 `~/hooks`

```bash
git clone <repo-url> ~/hooks
chmod +x ~/hooks/*.sh ~/hooks/wtmux

# wtmux 是独立命令，建议放进 PATH
ln -s ~/hooks/wtmux ~/bin/wtmux
```

### 2. 配置 Claude Code hooks

在 `~/.claude/settings.json` 的 `hooks` 中添加：

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [{ "async": true, "command": "bash ~/hooks/tmux-session-start.sh", "timeout": 5, "type": "command" }]
      }
    ],
    "Stop": [
      {
        "hooks": [{ "async": true, "command": "bash ~/hooks/tmux-stop.sh", "timeout": 5, "type": "command" }]
      }
    ],
    "PermissionRequest": [
      {
        "hooks": [{ "async": true, "command": "bash ~/hooks/tmux-permission-request.sh", "timeout": 3, "type": "command" }]
      }
    ],
    "PostToolUse": [
      {
        "hooks": [{ "async": true, "command": "bash ~/hooks/tmux-clear-permission-style.sh", "timeout": 3, "type": "command" }]
      }
    ],
    "PermissionDenied": [
      {
        "hooks": [{ "async": true, "command": "bash ~/hooks/tmux-clear-permission-style.sh", "timeout": 3, "type": "command" }]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [{ "async": true, "command": "bash ~/hooks/tmux-restore-name.sh", "timeout": 3, "type": "command" }]
      }
    ]
  }
}
```

### 3. 配置 tmux

在 `~/.tmux.conf` 中添加：

```bash
set-hook -g session-window-changed 'run-shell "bash ~/hooks/tmux-focus-strip-done.sh"'
```

### 4. 重新加载 tmux 配置

```bash
tmux source-file ~/.tmux.conf
```

## 用于其他 Agent

`agent-tmux-wrapper.sh` 可以包装任意 CLI agent，让它也获得 tmux 状态提示：

```bash
# 直接在 tmux 窗口中运行
~/hooks/agent-tmux-wrapper.sh pi
~/hooks/agent-tmux-wrapper.sh qoder --model gpt-4o
```

## 多 worktree 一键铺开：wtmux

`wtmux` 把一个仓库的每个 git worktree 各开一个 tmux 窗口，窗口名形如 `<目录>:<分支> [<端口>]`。端口取的是「cwd 落在该 worktree 内的进程正在监听的 TCP 端口」，所以一眼能看出哪个 worktree 起了 dev server、跑在哪个端口上。

```bash
wtmux                          # 用当前目录所在的仓库
wtmux ~/source/my-app          # 指定仓库（传子目录也行）
wtmux -c qodercli              # 每个窗口都跑这条命令，命令退出后 shell 留着
wtmux -- qoder --model gpt-4o  # 同上，-- 之后的内容整体作为命令
wtmux -r                       # 只刷新窗口名（重新探测端口），不 attach
wtmux -s my-app-dev            # 指定 / 覆盖 session 名（默认取仓库目录名）
wtmux -k                       # 先杀掉同名 session，干净重来
```

几个行为细节：

- **幂等**：已经有窗口的 worktree 会被跳过，新增 worktree 后重跑一次就能补上。
- **首次左右分屏为 70/30**：启动后使用原有快捷键或 `tmux split-window -h` 分屏，左侧自动占约 70%，右侧约 30%。由 `wtmux` 注册会话级钩子，无需修改 `~/.tmux.conf` 或快捷键；上下分屏、三个及以上 pane 和其他会话保持原来的行为。重新运行可为已有会话启用该规则，已有布局在下次符合条件的分屏前保持不变。
- **端口需要手动刷新**：起停 dev server 之后跑一次 `wtmux -r`，窗口名上的端口才会更新。在 tmux 里跑可以省略 `-s`（自动用当前 session）。
- **bare 仓库跳过**：没有工作区可开。
- **attach 语义**：不在 tmux 里就 `attach-session`，已经在 tmux 里则 `switch-client` 切过去。

和 wrapper 配合，每个 worktree 同时拉起 agent 和状态提示：

```bash
wtmux -c '~/hooks/agent-tmux-wrapper.sh qoder'
```

分屏行为的隔离集成测试（使用临时仓库和独立 tmux 服务，自动清理）：

```bash
bash tests/wtmux-splits.sh
```

## 依赖

- tmux
- jq
- Claude Code（或其他通过 wrapper 使用的 CLI agent）
- `wtmux` 另需 git；端口探测依赖 lsof，没装也能用，只是窗口名不带端口
