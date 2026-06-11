#!/bin/bash
# Universal agent wrapper — works with any CLI agent (pi, qoder, opencode, etc.)
#
# 执行位置: 在 tmux 中手动运行，用于包装非 Claude Code 的 CLI agent
# 它会模拟 Claude Code 的 SessionStart/Stop hook 行为，让其他 agent 也能
# 享受 tmux 窗口状态提示（DONE 标记、颜色变化等）。
#
# 用法: agent-tmux-wrapper.sh <agent-command> [args...]
# 示例: agent-tmux-wrapper.sh pi
#       agent-tmux-wrapper.sh qoder --model gpt-4o
#
# 无需 hooks 配置: 这不是 Claude Code hook，而是独立的命令行工具。
# 直接在 tmux 窗口中运行即可。

HOOKS_DIR="$HOME/hooks"
SESSIONS_FILE="$HOME/.claude/tmux-sessions.json"

if [ -z "$TMUX" ]; then
  exec "$@"
fi

SID=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Record session start
bash "$HOOKS_DIR/tmux-session-start.sh" "$SID"

# Run the agent
"$@"
EXIT_CODE=$?

# Mark DONE on exit
bash "$HOOKS_DIR/tmux-stop.sh" "$SID"

exit $EXIT_CODE
