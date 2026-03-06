#!/bin/bash
# Script for "Open Claude with File" Quick Action
# This script runs when you right-click a file/folder in Finder

# Force UTF-8 encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Get selected file(s) from stdin
F=$(cat)
[ -z "$F" ] && exit 0

# Resolve the claude binary location
export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin:$HOME/.npm-global/bin:$HOME/.local/bin"
CLAUDE=$(command -v claude 2>/dev/null || echo "claude")

show_accessibility_help() {
  osascript -e 'display dialog "macos blocked file auto-typing.\n\non first use, allow finder in:\nSystem Settings > Privacy & Security > Accessibility\n\nthen run \"Open Claude with File\" again." buttons {"OK"} default button 1 with icon caution with title "Claude Quick Actions"'
}

show_launch_error() {
  osascript -e 'display dialog "failed to launch claude from finder.\n\nmake sure Terminal and the claude cli are available, then try again." buttons {"OK"} default button 1 with icon caution with title "Claude Quick Actions"'
}

set_clipboard_text() {
  local text="$1"

  printf '%s' "$text" | pbcopy
  osascript - "$text" >/dev/null 2>&1 <<'APPLESCRIPT'
on run argv
  set the clipboard to item 1 of argv
end run
APPLESCRIPT
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

# Parse selected items into array (bash 3.2 compatible)
ITEMS=()
while IFS= read -r line; do
  [ -n "$line" ] && ITEMS+=("$line")
done <<< "$F"
COUNT=${#ITEMS[@]}

# Count files and folders
FILE_COUNT=0
FOLDER_COUNT=0
for item in "${ITEMS[@]}"; do
  if [ -d "$item" ]; then
    FOLDER_COUNT=$((FOLDER_COUNT + 1))
  elif [ -f "$item" ]; then
    FILE_COUNT=$((FILE_COUNT + 1))
  fi
done

# Validation: Check for invalid scenarios
if [ $FILE_COUNT -gt 0 ] && [ $FOLDER_COUNT -gt 0 ]; then
  osascript -e "display dialog \"Please select files OR folders, not both.\" buttons {\"OK\"} default button 1 with icon caution with title \"Claude Quick Actions\""
  exit 1
fi

if [ $FOLDER_COUNT -gt 1 ]; then
  osascript -e "display dialog \"Please select only one folder.\" buttons {\"OK\"} default button 1 with icon caution with title \"Claude Quick Actions\""
  exit 1
fi

if [ $FILE_COUNT -gt 10 ]; then
  osascript -e "display dialog \"Too many files selected (max 10). You selected $FILE_COUNT files.\" buttons {\"OK\"} default button 1 with icon caution with title \"Claude Quick Actions\""
  exit 1
fi

# Handle single folder
if [ $FOLDER_COUNT -eq 1 ]; then
  if ! launch_claude_in_dir "${ITEMS[0]}"; then
    show_launch_error
    exit 1
  fi
  exit 0
fi

# Handle files (single or multiple)
if [ $FILE_COUNT -gt 0 ]; then
  # Get the directory from first file
  DIRPATH=$(dirname "${ITEMS[0]}")
  EXISTING_CLAUDE_COUNT=$(pgrep -fc "claude" 2>/dev/null || echo 0)
  PROMPT_TEXT=""

  # Launch Claude in Terminal
  if ! launch_claude_in_dir "$DIRPATH"; then
    show_launch_error
    exit 1
  fi

  # Wait for the newly launched Claude process instead of matching an older session.
  for i in {1..20}; do
    CURRENT_CLAUDE_COUNT=$(pgrep -fc "claude" 2>/dev/null || echo 0)
    if [ "$CURRENT_CLAUDE_COUNT" -gt "$EXISTING_CLAUDE_COUNT" ] || [ "$CURRENT_CLAUDE_COUNT" -gt 0 ] && [ "$EXISTING_CLAUDE_COUNT" -eq 0 ]; then
      # Claude is running, wait 1 more second for UI to be ready
      sleep 1
      break
    fi
    sleep 0.3
  done

  # Give the Claude TUI a little extra time to focus its input before we paste.
  sleep 0.2

  # Build the full @file prompt once to avoid losing items to repeated paste events.
  for item in "${ITEMS[@]}"; do
    ITEMDIR=$(dirname "$item")
    FILENAME=$(basename "$item")

    # Determine if we need absolute path or basename
    if [ "$ITEMDIR" = "$DIRPATH" ]; then
      # File is in the same directory we cd into, use basename
      FILEPATH="$FILENAME"
    else
      # File is in a different directory, use absolute path
      FILEPATH="$item"
    fi

    # Check if filepath needs quotes (contains spaces or special chars)
    if [[ "$FILEPATH" =~ [[:space:]] ]] || [[ ! "$FILEPATH" =~ ^[a-zA-Z0-9./_-]+$ ]]; then
      TEXT="@\"$FILEPATH\""
    else
      TEXT="@$FILEPATH"
    fi
    PROMPT_TEXT="${PROMPT_TEXT}${TEXT} "
  done
  # Use both pbcopy and AppleScript to make sure the generated prompt stays in the system clipboard.
  set_clipboard_text "$PROMPT_TEXT"
  if ! osascript -e "tell application \"System Events\" to keystroke \"v\" using command down" >/dev/null 2>&1; then
    show_accessibility_help
    exit 1
  fi
fi
