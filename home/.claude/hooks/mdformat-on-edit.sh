#!/usr/bin/env bash
# Hook PostToolUse (Edit|Write) : reformate silencieusement en Markdown le
# fichier touché avec mdformat (reflow à 90 colonnes), pour éviter les lignes
# trop longues laissées par les agents. Ne fait rien hors fichiers .md/.markdown.
set -euo pipefail

command -v mdformat >/dev/null 2>&1 || exit 0

input="$(cat)"
file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"

[ -n "$file_path" ] || exit 0
[ -f "$file_path" ] || exit 0

case "$file_path" in
  *.md|*.markdown) ;;
  *) exit 0 ;;
esac

mdformat --wrap 90 "$file_path" >/dev/null 2>&1 || true

exit 0
