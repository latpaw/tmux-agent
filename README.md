# Claude Code Tmux Hooks

在 tmux 多窗口环境下增强 Claude Code 的会话状态可视化。通过 Claude Code 的 hooks 机制，在 tmux 窗口标签上实时反映每个会话的状态：等待授权、正在工作、已完成。

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

## 安装

### 1. 克隆到 `~/hooks`

```bash
git clone <repo-url> ~/hooks
chmod +x ~/hooks/*.sh
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

## 依赖

- tmux
- jq
- Claude Code（或其他通过 wrapper 使用的 CLI agent）
