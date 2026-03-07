#!/bin/bash
# Script for the "Open Claude with File" Finder service
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
CLAUDE_NAME=$(basename "$CLAUDE")

show_accessibility_help() {
  osascript -e 'display dialog "macos blocked file auto-typing.\n\non first use, allow finder in:\nSystem Settings > Privacy & Security > Accessibility\n\nthen run \"Open Claude with File\" again." buttons {"OK"} default button 1 with icon caution with title "Claude Quick Actions"'
}

show_launch_error() {
  osascript -e 'display dialog "failed to launch claude from finder.\n\nmake sure Terminal and the claude cli are available, then try again." buttons {"OK"} default button 1 with icon caution with title "Claude Quick Actions"'
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
  if ! launch_claude_and_wait_for_tab_process "${ITEMS[0]}"; then
    show_launch_error
    exit 1
  fi
  exit 0
fi

# Handle files (single or multiple)
if [ $FILE_COUNT -gt 0 ]; then
  # Get the directory from first file
  DIRPATH=$(dirname "${ITEMS[0]}")
  ORIGINAL_CLIPBOARD=$(pbpaste 2>/dev/null || true)
  PROMPT_TEXT=""

  # Launch Claude in Terminal
  if ! launch_claude_and_wait_for_tab_process "$DIRPATH"; then
    show_launch_error
    exit 1
  fi

  # Give the Claude TUI a little extra time to focus its input before we paste.
  sleep 0.5

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
    if [ -n "$PROMPT_TEXT" ]; then
      PROMPT_TEXT="${PROMPT_TEXT} "
    fi
    PROMPT_TEXT="${PROMPT_TEXT}${TEXT}"
  done

  # Copy the full prompt once so the user can also paste it manually if needed.
  set_clipboard_text "$PROMPT_TEXT"
  if ! osascript -e "tell application \"System Events\" to keystroke \"v\" using command down" >/dev/null 2>&1; then
    show_accessibility_help
    exit 1
  fi
  sleep 0.2
  set_clipboard_text "$ORIGINAL_CLIPBOARD"
fi
