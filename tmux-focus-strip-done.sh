#!/bin/bash
# Strip DONE suffix + clear style when user switches to a window
# Also updates styles for all windows based on DONE status
#
# 执行位置: tmux 自身的 hook（不是 Claude Code hook）
# 当用户切换到某个窗口时自动触发，移除当前窗口的 " DONE" 后缀，
# 并遍历所有窗口刷新样式（DONE 窗口保持绿底，普通窗口清除样式）。
#
# 配置方法: 在 ~/.tmux.conf 中添加：
#   set-hook -g session-window-changed 'run-shell "bash ~/hooks/tmux-focus-strip-done.sh"'

W=$(tmux display-message -p '#W')
case "$W" in
  *DONE) tmux rename-window "${W% DONE}" ;;
esac

# Update styles for all windows
tmux list-windows -F '#{window_index} #{window_name}' | while read idx name; do
  case "$name" in
    *DONE) tmux setw -t ":$idx" window-status-style "bg=colour34,fg=white" ;;
    *) tmux setw -t ":$idx" -u window-status-style ;;
  esac
done
