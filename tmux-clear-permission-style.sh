#!/bin/bash
# Clear yellow background on the correct tmux window after permission is handled
#
# 执行位置: Claude Code hooks — PostToolUse + PermissionDenied 事件
# 用户授权或拒绝权限后，清除黄色高亮，恢复窗口标签默认样式。
# 需要同时配置在两个 hook 事件上，确保无论授权还是拒绝都能清除。
#
# 配置方法: 在 ~/.claude/settings.json 的 hooks.PostToolUse 和
# hooks.PermissionDenied 中各添加一份：
#   {
#     "hooks": [{
#       "async": true,
#       "command": "bash ~/hooks/tmux-clear-permission-style.sh",
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
[ -z "$WIN_ID" ] && exit 0

tmux setw -t "$WIN_ID" -u window-status-style 2>/dev/null
