#!/usr/bin/env bash
# Hook PostToolUse (Edit|Write) : reformate silencieusement en Markdown le
# fichier touché avec mdformat (reflow à 90 colonnes par défaut), pour éviter
# les lignes trop longues laissées par les agents. Ne fait rien hors fichiers
# .md/.markdown. Si le projet définit son propre .mdformat.toml (racine git),
# ce fichier de config a priorité et le wrap forcé à 90 est désactivé, pour
# respecter le style déjà maintenu par le projet.
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

root="$(git -C "$(dirname "$file_path")" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$root" ] && [ -f "$root/.mdformat.toml" ]; then
  mdformat "$file_path" >/dev/null 2>&1 || true
else
  mdformat --wrap 90 "$file_path" >/dev/null 2>&1 || true
fi

exit 0
