#!/usr/bin/env bash
input=$(cat)

current_dir=$(echo "$input" | jq -r '.workspace.current_dir')
branch=$(git -C "$current_dir" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
model=$(echo "$input" | jq -r '.model.display_name')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- truecolor helpers ---
fg() { printf '\033[38;2;%s;%s;%sm' "$1" "$2" "$3"; }
RST=$'\033[0m'
BLUE=$(fg 97 175 239)
PURPLE=$(fg 198 120 221)
CYAN=$(fg 86 182 194)
ORANGE=$(fg 209 154 102)
GOLD=$(fg 229 181 103)
GREEN=$(fg 152 195 121)
YELLOW=$(fg 229 192 123)
RED=$(fg 224 108 117)
DIM=$(fg 92 99 112)

SEP="${DIM} │ ${RST}"

# pick a color for a 0-100 usage value (green -> yellow -> red)
usage_color() {
  if [ "$1" -ge 80 ]; then
    printf '%s' "$RED"
  elif [ "$1" -ge 50 ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}

# reset time (epoch seconds or ISO 8601) -> compact remaining (3d4h / 2h12m / 45m)
fmt_remaining() {
  local target now diff d h m
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    target="$1"
  else
    target=$(date -d "$1" +%s 2>/dev/null) || return 1
  fi
  now=$(date +%s)
  diff=$(( target - now ))
  [ "$diff" -lt 0 ] && diff=0
  d=$(( diff / 86400 ))
  h=$(( (diff % 86400) / 3600 ))
  m=$(( (diff % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then
    printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then
    printf '%dh%dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

parts=()

# --- dir ---
display_dir=$(echo "$current_dir" | sed "s|^$HOME|~|")
parts+=("${BLUE}󰉋 ${display_dir}${RST}")

# --- git branch ---
if [ -n "$branch" ]; then
  parts+=("${PURPLE}󰘬 ${branch}${RST}")
fi

# --- model ---
parts+=("${CYAN}󰚩 ${model}${RST}")

# --- effort level ---
if [ -n "$effort" ]; then
  parts+=("${ORANGE}󰓅 ${effort}${RST}")
fi

# --- context usage ---
if [ -n "$used" ]; then
  printf -v used_fmt "%.0f" "$used"
  parts+=("$(usage_color "$used_fmt")󰍛 ${used_fmt}%${RST}")
fi

# --- session cost ---
if [ -n "$cost" ]; then
  cost_fmt=$(awk -v c="$cost" 'BEGIN{printf "%.2f", c}')
  parts+=("${GOLD}\$${cost_fmt}${RST}")
fi

# --- rate limit: 5h window (+ reset countdown) ---
if [ -n "$five_hour" ]; then
  printf -v five_fmt "%.0f" "$five_hour"
  five_text="5h ${five_fmt}%"
  if [ -n "$five_reset" ]; then
    rem=$(fmt_remaining "$five_reset") && [ -n "$rem" ] && five_text="${five_text} ↺${rem}"
  fi
  parts+=("$(usage_color "$five_fmt")󰥔 ${five_text}${RST}")
fi

# --- rate limit: weekly (7d) window (+ reset countdown) ---
if [ -n "$seven_day" ]; then
  printf -v week_fmt "%.0f" "$seven_day"
  week_text="7d ${week_fmt}%"
  if [ -n "$seven_reset" ]; then
    rem=$(fmt_remaining "$seven_reset") && [ -n "$rem" ] && week_text="${week_text} ↺${rem}"
  fi
  parts+=("$(usage_color "$week_fmt")󰃭 ${week_text}${RST}")
fi

# --- join with separator ---
out=""
for i in "${!parts[@]}"; do
  if [ "$i" -gt 0 ]; then
    out+="$SEP"
  fi
  out+="${parts[$i]}"
done
printf '%s' "$out"
