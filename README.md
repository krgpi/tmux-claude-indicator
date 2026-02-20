# tmux-claude-indicator

tmux のステータスバーに [Claude Code](https://docs.anthropic.com/en/docs/claude-code) の入力待ち状態を表示する tmux プラグイン。

複数の tmux セッションで Claude Code を並行して使うとき、どのセッションが入力待ちかを一目で確認できます。

```
 1 project-a● 2 project-b○  3 project-c○
 ~~~~~~~~~~~  ~~~~~~~~~~~   ~~~~~~~~~~~
  現在の        他の           他の
  セッション    セッション     セッション
  (入力待ち)   (動作中)       (動作中)
```

## 機能

- **未読/既読インジケーター**: Claude Code が入力待ち → `●`（黄色）、動作中 → `○`
- **既読ロック**: ペインを確認した後、`idle_prompt` の再発火で通知が復活しない
- **セッション切り替え**: `prefix + 数字キー` でN番目のセッションに即切り替え
- **マウスクリック切り替え**: ステータスバーのセッション名をクリックで切り替え

## インストール

### TPM (Tmux Plugin Manager) を使う場合

`.tmux.conf` に追加:

```bash
set -g @plugin 'krgpi/tmux-claude-indicator'
```

`prefix + I` でインストール。

### 手動インストール

```bash
git clone https://github.com/karaage/tmux-claude-indicator.git ~/.tmux/plugins/tmux-claude-indicator
```

`.tmux.conf` に追加:

```bash
run-shell ~/.tmux/plugins/tmux-claude-indicator/claude-indicator.tmux
```

`tmux source ~/.tmux.conf` で反映。

## Claude Code hooks の設定

Claude Code の hooks を設定して、状態変化時にインジケーターを更新する必要があります。

`~/.claude/settings.json` に以下を追加してください:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "idle_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "~/.tmux/plugins/tmux-claude-indicator/scripts/notify.sh set-waiting-silent"
          }
        ]
      },
      {
        "matcher": "permission_prompt",
        "hooks": [
          {
            "type": "command",
            "command": "~/.tmux/plugins/tmux-claude-indicator/scripts/notify.sh set-waiting-log"
          }
        ]
      },
      {
        "matcher": "elicitation_dialog",
        "hooks": [
          {
            "type": "command",
            "command": "~/.tmux/plugins/tmux-claude-indicator/scripts/notify.sh set-waiting-silent"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.tmux/plugins/tmux-claude-indicator/scripts/notify.sh clear-waiting-log 'End(Session)'"
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.tmux/plugins/tmux-claude-indicator/scripts/notify.sh reset-lock"
          }
        ]
      }
    ]
  }
}
```

> **Note**: 既存の hooks 設定がある場合は、適宜マージしてください。

## カスタマイズ

`.tmux.conf` で以下のオプションを設定できます:

```bash
# ステータスバーのセッション一覧表示 (デフォルト: on)
set -g @claude-indicator-status-left 'on'

# prefix + 数字キーでセッション切り替え (デフォルト: on)
set -g @claude-indicator-session-switch 'on'

# マウスクリックでセッション切り替え (デフォルト: on)
set -g @claude-indicator-mouse-click 'on'

# ペイン選択時の既読処理 (デフォルト: on)
set -g @claude-indicator-mark-read 'on'

# 未読時のインジケータースタイル (デフォルト: #[fg=yellow,bold]●)
set -g @claude-indicator-waiting-style '#[fg=yellow,bold]●'

# 既読/動作中のインジケータースタイル (デフォルト: ○)
set -g @claude-indicator-idle-style '○'
```

## 仕組み

```
Claude Code (hooks)
    │
    ▼
notify.sh          ──→  /tmp/claude-waiting-{PANE_ID}  (未読フラグ)
                   ──→  /tmp/claude-read-{PANE_ID}     (既読ロック)
    │
    ▼ (tmux refresh-client -S)
    │
session-bar.sh     ←──  /tmp/claude-waiting-{PANE_ID} を参照
    │
    ▼
ステータスバー:  ● = 入力待ち (未読)  ○ = 動作中/既読
```

### 状態遷移

```
(1) Claude が入力待ちになる
    → idle_prompt hook → notify.sh set-waiting-silent
    → /tmp/claude-waiting-{PANE_ID} 作成 → ● 表示

(2) ユーザーがペインを選択して確認する
    → after-select-pane hook → mark-read.sh
    → /tmp/claude-waiting-{PANE_ID} 削除 → ○ 表示
    → /tmp/claude-read-{PANE_ID} 作成 (既読ロック)

(3) idle_prompt が再発火しても既読ロックがあるのでスキップ
    → set-waiting-silent → 既読ロック検出 → 何もしない

(4) ユーザーがプロンプトを送信する
    → UserPromptSubmit hook → notify.sh reset-lock
    → 両方のフラグをクリア → 次の完了で再び通知可能になる
```

## 要件

- tmux 3.0+
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code)
- jq (オプション: ログにメッセージ内容を記録する場合)

## ライセンス

MIT
