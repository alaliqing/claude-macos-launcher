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
[ -f "$HOME/.zprofile" ] && source "$HOME/.zprofile" 2>/dev/null
[ -f "$HOME/.zshrc" ]   && source "$HOME/.zshrc"   2>/dev/null
CLAUDE=$(which claude 2>/dev/null || echo "claude")

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
  CMD="cd $(printf '%q' "${ITEMS[0]}") && $CLAUDE"
  osascript -e "tell application \"Terminal\" to do script \"$CMD\""
  osascript -e "tell application \"Terminal\" to activate"
  exit 0
fi

# Handle files (single or multiple)
if [ $FILE_COUNT -gt 0 ]; then
  # Get the directory from first file
  DIRPATH=$(dirname "${ITEMS[0]}")
  CMD="cd $(printf '%q' "$DIRPATH") && $CLAUDE"

  # Launch Claude in Terminal
  osascript -e "tell application \"Terminal\" to do script \"$CMD\""
  osascript -e "tell application \"Terminal\" to activate"

  # Smart wait: check if claude process is running
  for i in {1..20}; do
    if pgrep -f "claude" > /dev/null 2>&1; then
      # Claude is running, wait 1 more second for UI to be ready
      sleep 1
      break
    fi
    sleep 0.3
  done

  # Auto-type all @filenames using clipboard (preserves Unicode)
  # Use absolute paths for files in different directories
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
      TEXT="@\"$FILEPATH\" "
    else
      TEXT="@$FILEPATH "
    fi

    # Use clipboard to preserve Unicode/Chinese characters
    echo -n "$TEXT" | pbcopy
    osascript -e "tell application \"System Events\" to keystroke \"v\" using command down"
  done
fi
