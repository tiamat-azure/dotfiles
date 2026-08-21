#!/usr/bin/env bash
# Affiche le transcript d'une session Claude Code (fichier .jsonl) en ne gardant que
# les tool_use / tool_result, avec un rendu colore neon.
#
# Usage:
#   show-session-log.sh                # session la plus recente du projet courant
#   show-session-log.sh -f <fichier>   # session explicite

set -euo pipefail

ORANGE='\033[1;38;2;255;176;32m'
CYAN='\033[38;2;34;211;238m'
GREEN='\033[38;2;57;255;136m'
VIOLET='\033[38;2;167;139;250m'
RESET='\033[0m'

usage() {
  echo "Usage: $(basename "$0") [-f <fichier.jsonl>]" >&2
  exit 1
}

file=""
while getopts ":f:h" opt; do
  case "$opt" in
    f) file="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

if [[ -z "$file" ]]; then
  project_dir="$HOME/.claude/projects/$(pwd | sed 's/\//-/g')"
  if [[ ! -d "$project_dir" ]]; then
    echo "Aucun repertoire de session trouve pour ce projet: $project_dir" >&2
    exit 1
  fi
  file=$(find "$project_dir" -maxdepth 1 -type f -name '*.jsonl' -printf '%T@ %p\n' \
    | sort -rn | head -1 | cut -d' ' -f2-)
  if [[ -z "$file" ]]; then
    echo "Aucune session .jsonl trouvee dans $project_dir" >&2
    exit 1
  fi
fi

if [[ ! -f "$file" ]]; then
  echo "Fichier introuvable: $file" >&2
  exit 1
fi

counter=0

while IFS= read -r record; do
  kind=$(jq -r '.type' <<<"$record")
  if [[ "$kind" == "tool_use" ]]; then
    counter=$((counter + 1))
    name=$(jq -r '.name' <<<"$record")
    desc=$(jq -r '.input.description // ""' <<<"$record")
    cmd=$(jq -r '.input.command // (.input | tostring)' <<<"$record")
    printf "\n${ORANGE}▶ %s #%d${RESET}\n" "$name" "$counter"
    [[ -n "$desc" ]] && printf "${CYAN}  %s${RESET}\n" "$desc"
    printf "${GREEN}  \$ %s${RESET}\n" "$cmd"
  else
    content=$(jq -r '.content | if type=="array" then map(.text? // (.|tostring)) | join(" ") elif type=="string" then . else tostring end | .[0:400]' <<<"$record")
    printf "${VIOLET}  → %s${RESET}\n" "$(sed '2,$s/^/    /' <<<"$content")"
  fi
done < <(jq -c '
  select(.message.content != null) |
  .message.content[]? |
  select(.type=="tool_use" or .type=="tool_result")
' "$file")
