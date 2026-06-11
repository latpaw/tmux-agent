#!/bin/bash
# Rename tmux window with DONE + green style when agent session stops
#
# 执行位置: Claude Code hooks — Stop 事件
# Claude 完成回答后，在 tmux 窗口名称末尾添加 " DONE" 并设置绿底白字，
# 方便用户在多窗口中快速识别哪些会话已完成。
#
# 配置方法: 在 ~/.claude/settings.json 的 hooks.Stop 中添加：
#   {
#     "hooks": [{
#       "async": true,
#       "command": "bash ~/hooks/tmux-stop.sh",
#       "timeout": 5,
#       "type": "command"
#     }]
#   }
INPUT=$(cat)
echo "$(date '+%Y-%m-%d %H:%M:%S') INPUT=$INPUT" >> /tmp/tmux-stop-debug.log
SID=$(echo "$INPUT" | jq -r '.session_id')
echo "$(date '+%Y-%m-%d %H:%M:%S') SID=$SID" >> /tmp/tmux-stop-debug.log
[ "$SID" = "null" ] || [ -z "$SID" ] && exit 0

FILE="$HOME/.claude/tmux-sessions.json"
[ ! -f "$FILE" ] && exit 0

WIN_ID=$(jq -r --arg sid "$SID" '.[$sid].windowId // empty' "$FILE")
echo "$(date '+%Y-%m-%d %H:%M:%S') WIN_ID=$WIN_ID FILE_CONTENT=$(cat "$FILE")" >> /tmp/tmux-stop-debug.log
[ -z "$WIN_ID" ] && echo "$(date '+%Y-%m-%d %H:%M:%S') EXIT: empty WIN_ID" >> /tmp/tmux-stop-debug.log && exit 0

# Only rename if not already ending with DONE
CURRENT=$(tmux display-message -t "$WIN_ID" -p '#W' 2>/dev/null)
echo "$(date '+%Y-%m-%d %H:%M:%S') CURRENT=$CURRENT tmux_exit=$?" >> /tmp/tmux-stop-debug.log
case "$CURRENT" in
  *DONE) echo "$(date '+%Y-%m-%d %H:%M:%S') SKIP: already DONE" >> /tmp/tmux-stop-debug.log ;;
  *)
    tmux rename-window -t "$WIN_ID" "${CURRENT} DONE" 2>/dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S') RENAME: exit=$? target=${CURRENT} DONE" >> /tmp/tmux-stop-debug.log
    tmux setw -t "$WIN_ID" window-status-style "bg=colour34,fg=white" 2>/dev/null
    echo "$(date '+%Y-%m-%d %H:%M:%S') STYLE: exit=$?" >> /tmp/tmux-stop-debug.log
    ;;
esac
