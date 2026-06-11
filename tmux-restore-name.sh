#!/bin/bash
# Restore tmux window name when user resumes interaction (removes DONE + clears style)
#
# 执行位置: Claude Code hooks — UserPromptSubmit 事件
# 当用户在某个窗口提交新消息时，移除 " DONE" 后缀并清除绿色背景，
# 恢复窗口名称到原始状态，表示会话重新活跃。
#
# 配置方法: 在 ~/.claude/settings.json 的 hooks.UserPromptSubmit 中添加：
#   {
#     "hooks": [{
#       "async": true,
#       "command": "bash ~/hooks/tmux-restore-name.sh",
#       "timeout": 3,
#       "type": "command"
#     }]
#   }
[ -z "$TMUX" ] && exit 0

INPUT=$(cat)
SID=$(echo "$INPUT" | jq -r '.session_id')
[ "$SID" = "null" ] || [ -z "$SID" ] && exit 0

FILE="$HOME/.claude/tmux-sessions.json"
[ ! -f "$FILE" ] && exit 0

WIN_ID=$(jq -r --arg sid "$SID" '.[$sid].windowId // empty' "$FILE")
WIN_NAME=$(jq -r --arg sid "$SID" '.[$sid].originalName // empty' "$FILE")
[ -z "$WIN_ID" ] && exit 0

# Only rename if current name ends with DONE
CURRENT=$(tmux display-message -t "$WIN_ID" -p '#W' 2>/dev/null)
case "$CURRENT" in
  *DONE)
    tmux rename-window -t "$WIN_ID" "$WIN_NAME" 2>/dev/null
    tmux setw -t "$WIN_ID" -u window-status-style 2>/dev/null
    ;;
esac
