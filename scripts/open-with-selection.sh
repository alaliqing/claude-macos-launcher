#!/bin/bash
# Script for the "Open Claude with Selection" Finder service
# This script runs when you right-click selected items in Finder

# Force UTF-8 encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Get selected file(s) from stdin
F=$(cat)
[ -z "$F" ] && exit 0

# Resolve the claude binary location
export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin:$HOME/.npm-global/bin:$HOME/.local/bin"
CLAUDE=$(command -v claude 2>/dev/null || echo "claude")
CLAUDE_NAME=$(basename "$CLAUDE")

is_chinese_system_language() {
  local primary_language

  primary_language=$(defaults read -g AppleLanguages 2>/dev/null | tr -d '[:space:][:punct:]' | head -n 1)
  [[ "$primary_language" == zh* ]]
}

show_accessibility_help() {
  if is_chinese_system_language; then
    osascript -e 'display dialog "macOS 阻止了自动输入选中内容。\n\n首次使用时，请先在这里允许“访达”：\n系统设置 > 隐私与安全性 > 辅助功能\n\n然后再次运行 \"Open Claude with Selection\"。" buttons {"好的"} default button 1 with icon caution with title "Claude Finder Services"'
  else
    osascript -e 'display dialog "macOS blocked selection auto-typing.\n\nOn first use, allow Finder in:\nSystem Settings > Privacy & Security > Accessibility\n\nThen run \"Open Claude with Selection\" again." buttons {"OK"} default button 1 with icon caution with title "Claude Finder Services"'
  fi
}

show_launch_error() {
  if is_chinese_system_language; then
    osascript -e 'display dialog "无法从访达启动 Claude。\n\n请确认 Terminal 和 Claude CLI 可用，然后再试一次。" buttons {"好的"} default button 1 with icon caution with title "Claude Finder Services"'
  else
    osascript -e 'display dialog "Failed to launch Claude from Finder.\n\nMake sure Terminal and the Claude CLI are available, then try again." buttons {"OK"} default button 1 with icon caution with title "Claude Finder Services"'
  fi
}

set_clipboard_text() {
  local text="$1"

  printf '%s' "$text" | pbcopy
}

launch_claude_in_dir() {
  local target_dir="$1"
  local cmd
  cmd="cd $(printf '%q' "$target_dir") && $CLAUDE"

  if ! osascript -e "tell application \"Terminal\" to do script \"$cmd\"" >/dev/null 2>&1; then
    return 1
  fi

  osascript -e "tell application \"Terminal\" to activate" >/dev/null 2>&1 || true
  return 0
}

launch_claude_and_wait_for_tab_process() {
  local target_dir="$1"
  local script_output
  local cmd
  cmd="cd $(printf '%q' "$target_dir") && $CLAUDE"

  script_output=$(osascript - "$cmd" "$CLAUDE_NAME" <<'APPLESCRIPT' 2>/dev/null
on run argv
  set shellCommand to item 1 of argv
  set expectedProcessName to item 2 of argv

  tell application "Terminal"
    set targetTab to do script shellCommand
    activate

    repeat 100 times
      try
        if expectedProcessName is in (processes of targetTab) then
          return "ready"
        end if
      end try
      delay 0.3
    end repeat
  end tell

  return "timeout"
end run
APPLESCRIPT
)

  [ "$script_output" = "ready" ]
}

common_parent_dir() {
  local common="$1"
  shift

  while [ $# -gt 0 ]; do
    local path="$1"
    shift

    while [ "${path#"$common"}" = "$path" ]; do
      common=$(dirname "$common")
      if [ "$common" = "/" ]; then
        break
      fi
    done
  done

  printf '%s\n' "$common"
}

# Parse selected items into array (bash 3.2 compatible)
ITEMS=()
while IFS= read -r line; do
  [ -n "$line" ] && ITEMS+=("$line")
done <<< "$F"
VALID_ITEMS=()
for item in "${ITEMS[@]}"; do
  if [ -d "$item" ] || [ -f "$item" ]; then
    VALID_ITEMS+=("$item")
  fi
done

COUNT=${#VALID_ITEMS[@]}
[ "$COUNT" -eq 0 ] && exit 0

if [ "$COUNT" -gt 10 ]; then
  osascript -e "display dialog \"Too many items selected (max 10). You selected $COUNT items.\" buttons {\"OK\"} default button 1 with icon caution with title \"Claude Finder Services\""
  exit 1
fi

SELECTION_ROOTS=()
for item in "${VALID_ITEMS[@]}"; do
  if [ -d "$item" ]; then
    SELECTION_ROOTS+=("$(dirname "$item")")
  elif [ -f "$item" ]; then
    SELECTION_ROOTS+=("$(dirname "$item")")
  fi
done

DIRPATH="${SELECTION_ROOTS[0]}"
if [ "$COUNT" -eq 1 ] && [ -d "${VALID_ITEMS[0]}" ]; then
  DIRPATH="${VALID_ITEMS[0]}"
elif [ "${#SELECTION_ROOTS[@]}" -gt 1 ]; then
  DIRPATH=$(common_parent_dir "$DIRPATH" "${SELECTION_ROOTS[@]:1}")
fi

ORIGINAL_CLIPBOARD=$(pbpaste 2>/dev/null || true)
PROMPT_TEXT=""

# Launch Claude in Terminal
if ! launch_claude_and_wait_for_tab_process "$DIRPATH"; then
  show_launch_error
  exit 1
fi

# Give the Claude TUI a little extra time to focus its input before we paste.
sleep 0.5

# Build the full @selection prompt once to avoid losing items to repeated paste events.
for item in "${VALID_ITEMS[@]}"; do
  ITEMDIR=$(dirname "$item")
  ITEMNAME=$(basename "$item")

  # Determine if we need absolute path or basename
  if [ "$COUNT" -eq 1 ] && [ -d "$item" ] && [ "$DIRPATH" = "$item" ]; then
    ITEMPATH="$item"
  elif [ "$ITEMDIR" = "$DIRPATH" ]; then
    ITEMPATH="$ITEMNAME"
  else
    ITEMPATH="$item"
  fi

  if [ -d "$item" ] && [ "${ITEMPATH%/}" = "$ITEMPATH" ]; then
    ITEMPATH="${ITEMPATH}/"
  fi

  # Check if the reference needs quotes (contains spaces or special chars)
  if [[ "$ITEMPATH" =~ [[:space:]] ]] || [[ ! "$ITEMPATH" =~ ^[a-zA-Z0-9./_-]+$ ]]; then
    TEXT="@\"$ITEMPATH\""
  else
    TEXT="@$ITEMPATH"
  fi
  if [ -n "$PROMPT_TEXT" ]; then
    PROMPT_TEXT="${PROMPT_TEXT} "
  fi
  PROMPT_TEXT="${PROMPT_TEXT}${TEXT}"
done

# Copy the full prompt once so the user can also paste it manually if needed.
set_clipboard_text "$PROMPT_TEXT"
if ! osascript -e "tell application \"System Events\" to keystroke \"v\" using command down" >/dev/null 2>&1; then
  set_clipboard_text "$ORIGINAL_CLIPBOARD"
  show_accessibility_help
  exit 1
fi
sleep 0.2
set_clipboard_text "$ORIGINAL_CLIPBOARD"
