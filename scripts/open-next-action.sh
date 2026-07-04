#!/usr/bin/env bash
# next-action.md（このフォルダのローカル版）を開く。
# Claude Code の SessionStart フック、および VSCode の folderOpen タスクから呼ばれる。
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILE="$DIR/next-action.md"

case "$(uname -s)" in
  Darwin) open "$FILE" ;;
  Linux)  xdg-open "$FILE" >/dev/null 2>&1 || true ;;
  *)      echo "このOSでは自動で開けません。next-action.md を手動で開いてください。" ;;
esac
