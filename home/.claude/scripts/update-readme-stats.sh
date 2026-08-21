#!/usr/bin/env bash
# Regenere le bloc de stats d'usage Claude Code (tokens, tool calls) dans README.md,
# entre les marqueurs <!-- STATS:START --> / <!-- STATS:END -->.
# Agrege TOUTES les sessions de TOUS les projets (~/.claude/projects/**/*.jsonl).
#
# Usage:
#   update-readme-stats.sh [chemin/vers/README.md]   # defaut: ./README.md

set -euo pipefail

readme="${1:-README.md}"

if [[ ! -f "$readme" ]]; then
  echo "Fichier introuvable: $readme" >&2
  exit 1
fi

if ! grep -q '<!-- STATS:START -->' "$readme" || ! grep -q '<!-- STATS:END -->' "$readme"; then
  echo "Marqueurs <!-- STATS:START --> / <!-- STATS:END --> absents de $readme" >&2
  exit 1
fi

mapfile -t files < <(find "$HOME/.claude/projects" -type f -name '*.jsonl' 2>/dev/null | sort)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "Aucune session .jsonl trouvee." >&2
  exit 1
fi

fmt_num() {
  local n="$1"
  if (( n >= 1000000 )); then
    awk -v n="$n" 'BEGIN { printf "%.1fM", n / 1000000 }'
  elif (( n >= 1000 )); then
    awk -v n="$n" 'BEGIN { printf "%.1fk", n / 1000 }'
  else
    printf "%s" "$n"
  fi
}

read -r total_input total_output total_cache_read total_cache_creation < <(jq -rs '
  [.[] | select(.message.usage != null) | .message.usage] as $u |
  ($u | map(.input_tokens // 0) | add // 0),
  ($u | map(.output_tokens // 0) | add // 0),
  ($u | map(.cache_read_input_tokens // 0) | add // 0),
  ($u | map(.cache_creation_input_tokens // 0) | add // 0)
  | @text
' "${files[@]}" | paste -sd' ')

total_tool_calls=$(jq -rs '
  [.[] | select(.message.content != null) | .message.content[]? | select(.type=="tool_use")] | length
' "${files[@]}")

mapfile -t models < <(jq -r '
  select(.message.usage != null and .message.model != null) | .message.model
' "${files[@]}" | grep -v '^<synthetic>$' | sort -u)

{
  echo "<!-- STATS:START -->"
  echo "<!-- Genere automatiquement par update-readme-stats.sh - ne pas editer a la main -->"
  echo
  echo "## Statistiques d'usage Claude Code"
  echo
  echo "_Cumul de toutes les sessions, tous projets - derniere mise a jour : $(date '+%Y-%m-%d %H:%M')_"
  echo
  echo "| Metrique | Total |"
  echo "|---|---|"
  echo "| Input tokens | $(fmt_num "$total_input") |"
  echo "| Output tokens | $(fmt_num "$total_output") |"
  echo "| Cache read tokens | $(fmt_num "$total_cache_read") |"
  echo "| Cache creation tokens | $(fmt_num "$total_cache_creation") |"
  echo "| Tool calls | $(fmt_num "$total_tool_calls") |"

  if [[ ${#models[@]} -gt 1 ]]; then
    echo
    echo "### Par modele"
    echo
    echo "| Modele | Input | Output | Cache read | Cache creation | Tool calls |"
    echo "|---|---|---|---|---|---|"
    for model in "${models[@]}"; do
      read -r m_input m_output m_cache_read m_cache_creation < <(jq -rs --arg model "$model" '
        [.[] | select(.message.usage != null and .message.model == $model) | .message.usage] as $u |
        ($u | map(.input_tokens // 0) | add // 0),
        ($u | map(.output_tokens // 0) | add // 0),
        ($u | map(.cache_read_input_tokens // 0) | add // 0),
        ($u | map(.cache_creation_input_tokens // 0) | add // 0)
        | @text
      ' "${files[@]}" | paste -sd' ')

      m_tool_calls=$(jq -rs --arg model "$model" '
        [.[] | select(.message.content != null and .message.model == $model) | .message.content[]? | select(.type=="tool_use")] | length
      ' "${files[@]}")

      echo "| $model | $(fmt_num "$m_input") | $(fmt_num "$m_output") | $(fmt_num "$m_cache_read") | $(fmt_num "$m_cache_creation") | $(fmt_num "$m_tool_calls") |"
    done
  fi

  echo "<!-- STATS:END -->"
} > /tmp/readme-stats-block.$$

awk -v blockfile=/tmp/readme-stats-block.$$ '
  BEGIN { while ((getline line < blockfile) > 0) block = block line "\n" }
  /<!-- STATS:START -->/ { printf "%s", block; skip=1; next }
  /<!-- STATS:END -->/ { skip=0; next }
  !skip { print }
' "$readme" > "$readme.tmp.$$"

rm -f /tmp/readme-stats-block.$$
mv "$readme.tmp.$$" "$readme"

echo "README.md mis a jour : $readme"
