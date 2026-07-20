#!/bin/bash
# Two-line status line, originally converted from the PS1 defined in
# ~/.bashrc, since restructured:
#   Line 1: cwd (bold blue) + git branch (muted), if any
#   Line 2: model + context-usage progress bar (dimmed)

input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')

# Resolve the git branch for cwd, failing gracefully (no git binary, not a
# repo, detached HEAD) by simply leaving $branch empty in every such case.
# --no-optional-locks avoids contending with any concurrent git process.
branch=""
if command -v git >/dev/null 2>&1; then
  if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
    # symbolic-ref fails/empties on detached HEAD; leave $branch empty rather
    # than falling back to a commit SHA.
  fi
fi

branch_segment=""
if [ -n "$branch" ]; then
  branch_segment=$(printf ' \033[2;35m\xef\x91\xa6 %s\033[00m' "$branch")
fi

# Prefer the pre-calculated context_window.used_percentage field. Fall back
# to deriving it from total_input_tokens / context_window_size when the
# pre-calculated field isn't present yet (e.g. before the first API call).
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -z "$used_pct" ]; then
  used_pct=$(echo "$input" | jq -r '
    (.context_window.total_input_tokens // empty) as $used
    | (.context_window.context_window_size // empty) as $size
    | if $used != null and $size != null and $size > 0
      then ($used / $size * 100)
      else empty
      end')
fi

bar=""
pct_label="?"
if [ -n "$used_pct" ]; then
  pct_rounded=$(printf '%.0f' "$used_pct")
  [ "$pct_rounded" -lt 0 ] && pct_rounded=0
  [ "$pct_rounded" -gt 100 ] && pct_rounded=100
  filled=$((pct_rounded / 10))
  empty=$((10 - filled))
  # Build the bar with an explicit loop rather than `printf ... $(seq 1 N)`:
  # when N is 0, seq produces no words, but printf still runs its format
  # once with the missing argument, which would wrongly emit one extra
  # block/shade character.
  for ((i = 0; i < filled; i++)); do bar+=$'\xe2\x96\x88'; done
  for ((i = 0; i < empty; i++)); do bar+=$'\xe2\x96\x91'; done
  pct_label="${pct_rounded}%"
fi

# Claude.ai subscription rate limits (5h session / 7-day weekly windows).
# These are only present for subscribers, and only after the first API
# response of the session, so they're omitted whenever absent rather than
# faked.
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

rl_segment=""
if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
  rl_parts=""
  if [ -n "$five_pct" ]; then
    rl_parts="5h:$(printf '%.0f' "$five_pct")%"
  fi
  if [ -n "$week_pct" ]; then
    week_part="7d:$(printf '%.0f' "$week_pct")%"
    if [ -n "$rl_parts" ]; then
      rl_parts="$rl_parts $week_part"
    else
      rl_parts="$week_part"
    fi
  fi
  rl_segment=$(printf ' \033[02m(%s)\033[00m' "$rl_parts")
fi

printf '\033[01;34m%s\033[00m%s\n\033[02m[%s]\033[00m \033[02m[%s] %s\033[00m%s' \
  "$cwd" "$branch_segment" "$model" "$bar" "$pct_label" "$rl_segment"
