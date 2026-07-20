#!/bin/bash
# Claude Code status line: model name + context window usage percentage
# + current context token count + cumulative session token count

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
current_tokens=$(echo "$input" | jq -r '((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0))')
transcript_path=$(echo "$input" | jq -r '.transcript_path // empty')

# Sum token usage across every recorded API call in the transcript to get a
# cumulative total for the session (not just what's currently in context).
cumulative_tokens=0
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

if [ -n "$used" ]; then
    printf '\033[2m%s\033[0m \033[2m|\033[0m \033[2mCtx: %.0f%%\033[0m \033[2m|\033[0m \033[2mTokens: %s\033[0m \033[2m|\033[0m \033[2mSession: %s\033[0m' \
        "$model" "$used" "$current_fmt" "$cumulative_fmt"
else
    printf '\033[2m%s\033[0m \033[2m|\033[0m \033[2mTokens: %s\033[0m \033[2m|\033[0m \033[2mSession: %s\033[0m' \
        "$model" "$current_fmt" "$cumulative_fmt"
fi
