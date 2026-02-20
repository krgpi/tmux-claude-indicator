#!/bin/bash
# tmux-claude-indicator - TPM エントリポイント
# Claude Code の入力待ち状態をtmuxステータスバーに表示する

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$CURRENT_DIR/scripts/helpers.sh"

# status-left にセッション一覧 + インジケーターを表示
setup_status_left() {
  local enabled
  enabled=$(get_tmux_option "@claude-indicator-status-left" "on")
  [ "$enabled" != "on" ] && return

  tmux set-option -g status-left-length 200
  tmux set-option -g status-left "#($CURRENT_DIR/scripts/session-bar.sh)"
  # window-status-format を空にしてセッション一覧に集約
  tmux set-option -g window-status-format ""
  tmux set-option -g window-status-current-format ""
}

# ペイン選択時に既読処理を実行
setup_mark_read() {
  local enabled
  enabled=$(get_tmux_option "@claude-indicator-mark-read" "on")
  [ "$enabled" != "on" ] && return

  tmux set-hook -g after-select-pane "run-shell -b '$CURRENT_DIR/scripts/mark-read.sh #{pane_id}'"
}

# prefix + 数字キーでセッション切り替え
setup_session_switch() {
  local enabled
  enabled=$(get_tmux_option "@claude-indicator-session-switch" "on")
  [ "$enabled" != "on" ] && return

  local i
  for i in $(seq 1 9); do
    tmux bind-key "$i" run-shell "$CURRENT_DIR/scripts/switch-session.sh $i"
  done
}

# ステータスバーのマウスクリックでセッション切り替え
setup_mouse_click() {
  local enabled
  enabled=$(get_tmux_option "@claude-indicator-mouse-click" "on")
  [ "$enabled" != "on" ] && return

  tmux bind-key -n MouseDown1StatusLeft run-shell "$CURRENT_DIR/scripts/click-session.sh #{mouse_x}"
}

main() {
  setup_status_left
  setup_mark_read
  setup_session_switch
  setup_mouse_click
}

main
