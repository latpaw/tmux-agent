#!/bin/bash
# Set yellow background on the correct tmux window when permission/confirm is needed
#
# 执行位置: Claude Code hooks — PermissionRequest 事件
# 当 Claude 需要用户授权时，将对应 tmux 窗口标签变为黄底黑字，
# 方便用户在多窗口中一眼看到哪个窗口需要操作。
#
# 配置方法: 在 ~/.claude/settings.json 的 hooks.PermissionRequest 中添加：
#   {
#     "hooks": [{
#       "async": true,
#       "command": "bash ~/hooks/tmux-permission-request.sh",
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

tmux setw -t "$WIN_ID" window-status-style "bg=colour214,fg=black" 2>/dev/null
