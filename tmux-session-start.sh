#!/bin/bash
# Record tmux window info when an agent session starts
#
# 执行位置: Claude Code hooks — SessionStart 事件
# 脚本通过 stdin 接收 JSON（包含 session_id），记录当前 tmux 窗口信息到
# ~/.claude/tmux-sessions.json，供后续 hook 脚本定位正确的窗口。
#
# 配置方法: 在 ~/.claude/settings.json 的 hooks.SessionStart 中添加：
#   {
#     "hooks": [{
#       "async": true,
#       "command": "bash ~/hooks/tmux-session-start.sh",
#       "timeout": 5,
#       "type": "command"
#     }]
#   }
[ -z "$TMUX" ] && exit 0

INPUT=$(cat)
SID=$(echo "$INPUT" | jq -r '.session_id')
[ "$SID" = "null" ] || [ -z "$SID" ] && exit 0

WIN_ID=$(tmux display-message -p '#{session_name}:#{window_index}')
WIN_NAME=$(tmux display-message -p '#W')

# Strip trailing DONE suffix if present (leftover from previous session)
WIN_NAME="${WIN_NAME% DONE}"

# Restore clean name immediately
tmux rename-window -t "$WIN_ID" "$WIN_NAME" 2>/dev/null
tmux setw -t "$WIN_ID" -u window-status-style 2>/dev/null

FILE="$HOME/.claude/tmux-sessions.json"
[ ! -f "$FILE" ] && echo '{}' > "$FILE"
jq --arg sid "$SID" --arg wid "$WIN_ID" --arg name "$WIN_NAME" \
  '.[$sid] = {windowId: $wid, originalName: $name}' "$FILE" > "$FILE.tmp" \
  && mv "$FILE.tmp" "$FILE"
