#!/bin/bash
# Claude Code status line: model name + effort level
# + tok (context tokens, with context-window usage %)
# + tools (calls since last question / cumulative total over the session)
# + session (cumulative session tokens)

# Force a C decimal separator so printf '%.0f' accepts jq's dotted floats.
export LC_NUMERIC=C

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
# Effort level is only reported for models that support it.
effort=$(echo "$input" | jq -r '.effort.level // empty')
[ -n "$effort" ] && model="$model ($effort)"
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
current_tokens=$(echo "$input" | jq -r '((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0))')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

# Sum token usage across every recorded API call in the transcript to get a
# cumulative total for the session (not just what's currently in context).
# Also count tool calls: total over the session, and since the last real
# user question (i.e. excluding synthetic user turns made of tool_result blocks).
cumulative_tokens=0
tool_calls_since=0
tool_calls_total=0
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
    cumulative_tokens=$(jq -s '
        [.[] | select(.message.usage != null) |
            (.message.usage.input_tokens // 0)
            + (.message.usage.output_tokens // 0)
            + (.message.usage.cache_creation_input_tokens // 0)
            + (.message.usage.cache_read_input_tokens // 0)
        ] | add // 0
    ' "$transcript_path" 2>/dev/null)
    [ -z "$cumulative_tokens" ] && cumulative_tokens=0

    read -r tool_calls_since tool_calls_total <<< "$(jq -sr '
        to_entries as $e
        | ($e | map(select(.value.type=="user" and ((.value.message.content|type)=="string" or (.value.message.content|map(.type)|index("tool_result"))==null))) | last | .key // -1) as $lastq
        | ($e | map(select(.key > $lastq and .value.type=="assistant")) | map(.value.message.content[]? | select(.type=="tool_use")) | length) as $since
        | ($e | map(.value) | map(select(.type=="assistant")) | map(.message.content[]? | select(.type=="tool_use")) | length) as $total
        | "\($since) \($total)"
    ' "$transcript_path" 2>/dev/null)"
    [ -z "$tool_calls_since" ] && tool_calls_since=0
    [ -z "$tool_calls_total" ] && tool_calls_total=0
fi

# Format large token counts as e.g. 12.3k / 1.2M for readability.
fmt_tokens() {
    local n=$1
    if [ "$n" -ge 1000000 ] 2>/dev/null; then
        awk -v n="$n" 'BEGIN { printf "%.1fM", n/1000000 }'
    elif [ "$n" -ge 1000 ] 2>/dev/null; then
        awk -v n="$n" 'BEGIN { printf "%.1fk", n/1000 }'
    else
        printf '%s' "$n"
    fi
}

current_fmt=$(fmt_tokens "$current_tokens")
cumulative_fmt=$(fmt_tokens "$cumulative_tokens")

# Neon 256-color codes for the traffic-light indicators.
NEON_GREEN='\033[38;5;118m'
NEON_ORANGE='\033[38;5;202m'
NEON_RED='\033[38;5;196m'
NEON_CYAN_BOLD='\033[1m\033[38;5;51m'
NEON_PINK='\033[38;5;198m'
RESET='\033[0m'

# Pick a neon color given a value and its (low, high-inclusive) thresholds:
# green below low, orange from low to high (inclusive), red above high.
color_for() {
    local value=$1 low=$2 high=$3
    if awk -v v="$value" -v l="$low" 'BEGIN { exit !(v < l) }'; then
        printf '%s' "$NEON_GREEN"
    elif awk -v v="$value" -v h="$high" 'BEGIN { exit !(v <= h) }'; then
        printf '%s' "$NEON_ORANGE"
    else
        printf '%s' "$NEON_RED"
    fi
}

if [ -n "$used" ]; then
    tok_color=$(color_for "$used" 20 40)
    tokens_part=$(printf '\033[1m%bTok: %s (%.0f%%)%b' "$tok_color" "$current_fmt" "$used" "$RESET")
else
    tokens_part=$(printf 'Tok: %s' "$current_fmt")
fi

tools_since_color=$(color_for "$tool_calls_since" 9 20)
tools_total_color=$(color_for "$tool_calls_total" 9 20)
tools_part=$(printf '\033[1m%bTools %s%b\033[1m%b/%b\033[1m%s%b' \
    "$tools_since_color" "$tool_calls_since" "$RESET" \
    "$tools_since_color" "$tools_total_color" "$tool_calls_total" "$RESET")

sep=$(printf '%b|%b' "$NEON_CYAN_BOLD" "$RESET")
model_part=$(printf '%b%s%b' "$NEON_CYAN_BOLD" "$model" "$RESET")

session_part=$(printf '\033[1m%bSession: %s%b' "$NEON_PINK" "$cumulative_fmt" "$RESET")

printf '%s %s %s %s %s %s %s' \
    "$model_part" "$sep" "$tokens_part" "$sep" "$tools_part" "$sep" "$session_part"
