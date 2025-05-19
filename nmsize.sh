#!/bin/bash

set -eo pipefail

# Constants
BOLD="\033[1m"
RESET="\033[0m"
GREEN="\033[38;5;82m"
YELLOW="\033[38;5;220m"
RED="\033[38;5;196m"
ORANGE="\033[38;5;208m"

PACKAGE="nmsize"
VERSION="1.0.2"

# Configurable options
DEPTH=10
SORT="alpha"
LIMIT=""
DIR="."
IGNORE_DOTS=true
IGNORE_PATTERNS=()
MAX_DOTS=50

usage() {
  echo "Usage: $0 [OPTIONS] [DIRECTORY]"
  echo
  echo "Lists all \`node_modules\` folders and display their disk sizes."
  echo
  echo "Options:"
  echo "  -d, --depth NUM           Set max search depth (default: 10)"
  echo "  -s, --sort alpha|asc|desc Sort by name (alpha), size ascending (asc), or size descending (desc) — default: alpha"
  echo "  -l, --limit NUM           Limit the number of results (default: all)"
  echo "  -i, --ignore PATTERN      Ignore matching path pattern (can be used multiple times)"
  echo "      --ignore-dots BOOL    Exclude hidden directories (true/false, default: true)"
  echo "  -V, --version             Show version information"
  echo "  -h, --help                Show this help message"
  exit 0
}

show_version() {
  echo "$PACKAGE v$VERSION"
  exit 0
}

show_progress_dots() {
  local pid=$1
  local interval=$2
  local dots=0

  if [[ "$IGNORE_DOTS" == "false" ]]; then
    printf "..."
    wait "$pid"
    return
  fi

  while kill -0 "$pid" 2>/dev/null; do
    if (( dots < MAX_DOTS )); then
      printf "."
      dots=$((dots + 1))
    fi
    sleep "$interval"
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--depth)
      DEPTH="$2"
      shift 2
      ;;
    -s|--sort)
      SORT="$2"
      if [[ "$SORT" != "desc" && "$SORT" != "asc" && "$SORT" != "alpha" ]]; then
        echo "Error: sort option must be 'alpha', 'desc' or 'asc'"
        exit 1
      fi
      shift 2
      ;;
    -l|--limit)
      LIMIT="$2"
      shift 2
      ;;
    -i|--ignore)
      IGNORE_PATTERNS+=("$2")
      shift 2
      ;;
    --ignore-dots)
      IGNORE_DOTS="$2"
      shift 2
      ;;
    -V|--version)
      show_version
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [[ -d "$1" ]]; then
        DIR="$1"
        shift
      else
        echo "Invalid directory: $1"
        exit 1
      fi
      ;;
  esac
done

if [[ ! -d "$DIR" ]]; then
  printf "Error: '%s' is not a valid directory\n" "$DIR"
  exit 1
fi

printf "%b----- %b⚡ NODE MODULES SIZE SCANNER  🔍%b -----%b\n\n" "$RESET" "$BOLD$GREEN" "$RESET" "$RESET"

format_size() {
  local size=$1
  local gb=$(( size / 1073741824 ))
  local mb=$(( size / 1048576 ))
  local kb=$(( size / 1024 ))

  if (( gb > 0 )); then
    local dec=$(( (size % 1073741824) * 100 / 1073741824 ))
    echo "${gb}.$(printf "%02d" $dec) GB"
  elif (( mb > 0 )); then
    local dec=$(( (size % 1048576) * 100 / 1048576 ))
    echo "${mb}.$(printf "%02d" $dec) MB"
  elif (( kb > 0 )); then
    local dec=$(( (size % 1024) * 100 / 1024 ))
    echo "${kb}.$(printf "%02d" $dec) KB"
  else
    echo "$size B"
  fi
}

TEMP_FILE=$(mktemp "/tmp/nodemodules_temp.XXXXXX")
NODE_MODULES_LIST=$(mktemp "/tmp/nodemodules_list.XXXXXX")

# shellcheck disable=SC2317
cleanup() {
  rm -f "$TEMP_FILE" "$NODE_MODULES_LIST" 2>/dev/null || true
}

trap cleanup EXIT HUP INT QUIT TERM

printf "Starting search with max depth: %b%s%b\n" "$YELLOW" "$DEPTH" "$RESET"

printf "Searching for node_modules "

FIND_CMD=(find "$DIR" -maxdepth "$DEPTH" \( )
if [[ "$IGNORE_DOTS" == "true" ]]; then
  FIND_CMD+=(-path "*/.*" -prune -o)
fi
for pattern in "${IGNORE_PATTERNS[@]}"; do
  FIND_CMD+=(-path "*$pattern*" -prune -o)
done
FIND_CMD+=(-name "node_modules" -prune -print \))

("${FIND_CMD[@]}" > "$NODE_MODULES_LIST" 2>/dev/null) &
FIND_PID=$!
INTERVAL=0.2
show_progress_dots "$FIND_PID" "$INTERVAL"
wait "$FIND_PID"
printf "  %b✓%b\n" "$GREEN" "$RESET"

if [[ ! -s "$NODE_MODULES_LIST" ]]; then
  printf "%bNo node_modules directories found%b\n\n" "$RED" "$RESET"
  exit 0
fi

printf "Calculating sizes "

echo "PATH,SIZE_BYTES" > "$TEMP_FILE"

(
  while IFS= read -r module; do
    size=$(du -sk "$module" 2>/dev/null | cut -f1)
    if [[ -n "$size" ]]; then
      size_bytes=$((size * 1024))
      echo "$module,$size_bytes" >> "$TEMP_FILE"
    fi
  done < "$NODE_MODULES_LIST"
) &

CALC_PID=$!
INTERVAL=0.1
show_progress_dots "$CALC_PID" "$INTERVAL"
wait "$CALC_PID"
printf "  %b✓%b\n" "$GREEN" "$RESET"

if [[ -n "$LIMIT" ]]; then
  if [[ "$SORT" == "alpha" ]]; then
    SORTED_DATA=$(tail -n +2 "$TEMP_FILE" | sort -f -V -t, -k1 | head -n "$LIMIT")
  elif [[ "$SORT" == "asc" ]]; then
    SORTED_DATA=$(tail -n +2 "$TEMP_FILE" | sort -n -t, -k2 | head -n "$LIMIT")
  elif [[ "$SORT" == "desc" ]]; then
    SORTED_DATA=$(tail -n +2 "$TEMP_FILE" | sort -rn -t, -k2 | head -n "$LIMIT")
  fi
else
  if [[ "$SORT" == "alpha" ]]; then
    SORTED_DATA=$(tail -n +2 "$TEMP_FILE" | sort -f -V -t, -k1)
  elif [[ "$SORT" == "asc" ]]; then
    SORTED_DATA=$(tail -n +2 "$TEMP_FILE" | sort -n -t, -k2)
  elif [[ "$SORT" == "desc" ]]; then
    SORTED_DATA=$(tail -n +2 "$TEMP_FILE" | sort -rn -t, -k2)
  fi
fi

TOTAL_SIZE=0
COUNT=0

printf "\nRESULTS\n\n"

while IFS=, read -r PATH SIZE_BYTES || [[ -n "$PATH" && -n "$SIZE_BYTES" ]]; do
  HUMAN_SIZE=$(format_size "$SIZE_BYTES")
  PRETTY_PATH="${PATH#"$DIR"/}"
  [[ "$PRETTY_PATH" == "$PATH" ]] && PRETTY_PATH="$PATH"

  if (( SIZE_BYTES >= 104857600 )); then COLOR="$RED"
  elif (( SIZE_BYTES >= 52428800 )); then COLOR="$ORANGE"
  elif (( SIZE_BYTES >= 10485760 )); then COLOR="$YELLOW"
  else COLOR="$GREEN"
  fi

  printf "%-60.60s │ %b%15s%b\n" "$PRETTY_PATH" "$COLOR" "$HUMAN_SIZE" "$RESET"
  TOTAL_SIZE=$((TOTAL_SIZE + SIZE_BYTES))
  COUNT=$((COUNT + 1))
done <<< "$SORTED_DATA"

printf "\n"
if command -v tput >/dev/null 2>&1; then
  COLUMNS=$(tput cols)
else
  COLUMNS=80
fi
TOTAL_LABEL="TOTAL"
SIZE_LABEL="$(format_size "$TOTAL_SIZE")"
PADDING=$(( COLUMNS - ${#TOTAL_LABEL} - ${#SIZE_LABEL} - 2 ))
printf "%s" "$TOTAL_LABEL"
printf "%*s" "$PADDING" ""
printf "%b%s%b\n" "$RED" "$SIZE_LABEL" "$RESET"
printf "\n"

exit 0
