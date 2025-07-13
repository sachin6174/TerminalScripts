#!/usr/bin/env bash
#
# print.sh — big block letters in a blue→green gradient (high-contrast),
#            with interactive color input if none provided
#

# ── DEFAULT CONFIG ────────────────────────────────────────────────────────────

FONT="big"    # figlet font

# ── HELP & USAGE ──────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $0 [-f FONT] [-s START_COLOR] [-e END_COLOR] TEXT…

  -f FONT           figlet font name (default: big)
  -s START_COLOR    start color (RGB “R,G,B” or hex “#RRGGBB”)
  -e END_COLOR      end color   (RGB “R,G,B” or hex “#RRGGBB”)

If -s or -e are omitted, you’ll be prompted to enter them interactively.
EOF
  exit 1
}

# ── PARSE OPTIONS ─────────────────────────────────────────────────────────────

while getopts ":f:s:e:h" opt; do
  case $opt in
    f) FONT="$OPTARG" ;;
    s) START_COLOR_RAW="$OPTARG" ;;
    e) END_COLOR_RAW="$OPTARG" ;;
    h|\?) usage ;;
  esac
done
shift $((OPTIND -1))

[ $# -lt 1 ] && usage

TEXT="$*"

# ── DEPENDENCIES ─────────────────────────────────────────────────────────────

for cmd in figlet awk; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "🛠 $cmd not found; please install it and re-run."
    exit 1
  fi
done

# ── COLOR PARSING FUNCTIONS ──────────────────────────────────────────────────

# parse “R,G,B” or “#RRGGBB” into three integers
parse_color() {
  local raw=$1
  if [[ $raw =~ ^#?([A-Fa-f0-9]{6})$ ]]; then
    hex=${BASH_REMATCH[1]}
    printf "%d %d %d" "$((0x${hex:0:2}))" "$((0x${hex:2:2}))" "$((0x${hex:4:2}))"
  elif [[ $raw =~ ^([0-9]{1,3}),([0-9]{1,3}),([0-9]{1,3})$ ]]; then
    printf "%d %d %d" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}"
  else
    echo "Invalid color format: $raw" >&2
    exit 1
  fi
}

# ── INTERACTIVE PROMPT ───────────────────────────────────────────────────────

prompt_for_color() {
  local prompt="$1"
  local raw
  while true; do
    read -p "$prompt (RGB “R,G,B” or hex “#RRGGBB”): " raw
    if [[ $raw =~ ^#?([A-Fa-f0-9]{6})$ ]] || [[ $raw =~ ^[0-9]{1,3},[0-9]{1,3},[0-9]{1,3}$ ]]; then
      echo "$raw" && break
    else
      echo "  → Invalid format, try again."
    fi
  done
}

# ── RESOLVE START & END COLORS ───────────────────────────────────────────────

# if not passed via flags, prompt
[ -z "$START_COLOR_RAW" ] && START_COLOR_RAW=$(prompt_for_color "Enter START color")
[ -z "$END_COLOR_RAW"   ] && END_COLOR_RAW=$(prompt_for_color "Enter END   color")

read START_R START_G START_B < <(parse_color "$START_COLOR_RAW")
read END_R   END_G   END_B   < <(parse_color "$END_COLOR_RAW")

# ── RENDER via figlet ─────────────────────────────────────────────────────────

ART=$(figlet -f "$FONT" "$TEXT")

# ── COUNT LINES ───────────────────────────────────────────────────────────────

total=$(printf "%s\n" "$ART" | wc -l)
(( total <= 1 )) && total=1

# ── PRINT with gradient ───────────────────────────────────────────────────────

i=0
printf "%s\n" "$ART" | while IFS= read -r line; do
  if (( total > 1 )); then
    pct=$(awk "BEGIN{printf \"%.4f\", $i/($total-1)}")
  else
    pct=0
  fi

  R=$(awk "BEGIN{printf \"%d\", $START_R + ($END_R - $START_R)*$pct}")
  G=$(awk "BEGIN{printf \"%d\", $START_G + ($END_G - $START_G)*$pct}")
  B=$(awk "BEGIN{printf \"%d\", $START_B + ($END_B - $START_B)*$pct}")

  printf "\033[38;2;%d;%d;%dm%s\033[0m\n" "$R" "$G" "$B" "$line"
  ((i++))
done
