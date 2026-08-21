#!/usr/bin/env bash
# Calcule les statistiques d'usage (tokens input/output, cache, tool calls) a partir
# des traces Claude Code (.jsonl) d'un projet, avec un rendu colore neon.
#
# Usage:
#   claude-usage-stats.sh                # session la plus recente du projet courant
#   claude-usage-stats.sh -a             # toutes les sessions du projet courant
#   claude-usage-stats.sh -f <fichier>   # session explicite
#   claude-usage-stats.sh -d <dossier>   # toutes les sessions d'un dossier de projet

set -euo pipefail

ORANGE='\033[1;38;2;255;176;32m'
CYAN='\033[38;2;34;211;238m'
GREEN='\033[38;2;57;255;136m'
VIOLET='\033[38;2;167;139;250m'
PINK='\033[38;2;255;92;205m'
RESET='\033[0m'

usage() {
  echo "Usage: $(basename "$0") [-a] [-f <fichier.jsonl>] [-d <dossier>]" >&2
  exit 1
}

all=false
file=""
dir=""
while getopts ":af:d:h" opt; do
  case "$opt" in
    a) all=true ;;
    f) file="$OPTARG" ;;
    d) dir="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

project_dir="${dir:-$HOME/.claude/projects/$(pwd | sed 's/\//-/g')}"

if [[ -n "$file" ]]; then
  files=("$file")
elif $all || [[ -n "$dir" ]]; then
  if [[ ! -d "$project_dir" ]]; then
    echo "Aucun repertoire de session trouve pour ce projet: $project_dir" >&2
    exit 1
  fi
  mapfile -t files < <(find "$project_dir" -maxdepth 1 -type f -name '*.jsonl' | sort)
else
  if [[ ! -d "$project_dir" ]]; then
    echo "Aucun repertoire de session trouve pour ce projet: $project_dir" >&2
    exit 1
  fi
  f=$(find "$project_dir" -maxdepth 1 -type f -name '*.jsonl' -printf '%T@ %p\n' \
    | sort -rn | head -1 | cut -d' ' -f2-)
  files=("$f")
fi

if [[ ${#files[@]} -eq 0 || -z "${files[0]}" ]]; then
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

print_stats() {
  local label="$1"
  local input=0 output=0 cache_read=0 cache_creation=0 tool_calls=0

  while IFS=$'\t' read -r i o cr cc; do
    input=$((input + i))
    output=$((output + o))
    cache_read=$((cache_read + cr))
    cache_creation=$((cache_creation + cc))
  done < <(jq -r '
    select(.message.usage != null) | .message.usage |
    [.input_tokens // 0, .output_tokens // 0, .cache_read_input_tokens // 0, .cache_creation_input_tokens // 0] | @tsv
  ' "${files[@]}")

  tool_calls=$(jq -r '
    select(.message.content != null) | .message.content[]? | select(.type=="tool_use") | .name
  ' "${files[@]}" | wc -l)

  printf "\n${ORANGE}▶ %s${RESET}\n" "$label"
  printf "${CYAN}  Input tokens        : ${GREEN}%s${RESET}\n" "$(fmt_num "$input")"
  printf "${CYAN}  Output tokens       : ${GREEN}%s${RESET}\n" "$(fmt_num "$output")"
  printf "${CYAN}  Cache read tokens   : ${VIOLET}%s${RESET}\n" "$(fmt_num "$cache_read")"
  printf "${CYAN}  Cache creation      : ${VIOLET}%s${RESET}\n" "$(fmt_num "$cache_creation")"
  printf "${CYAN}  Tool calls          : ${PINK}%s${RESET}\n" "$(fmt_num "$tool_calls")"
}

for f in "${files[@]}"; do
  [[ -f "$f" ]] || { echo "Fichier introuvable: $f" >&2; exit 1; }
done

if [[ ${#files[@]} -eq 1 && -z "$dir" && "$all" == false ]]; then
  print_stats "Session : $(basename "${files[0]}")"
else
  print_stats "Projet : ${#files[@]} session(s) - $project_dir"
fi
