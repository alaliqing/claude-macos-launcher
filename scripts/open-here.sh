#!/bin/bash
# Script for "Open Claude Here" Quick Action
# This script runs when you press the keyboard shortcut (Command+Option+Shift+C)

# Force UTF-8 encoding
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Get current Finder window path using AppleScript
FINDER_PATH=$(osascript -e "tell application \"Finder\" to if (count of Finder windows) > 0 then get POSIX path of (target of front Finder window as alias)" 2>/dev/null)

# Fallback to home directory if no Finder window is open
[ -z "$FINDER_PATH" ] && FINDER_PATH="$HOME"

# Resolve the claude binary location
export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin:$HOME/.npm-global/bin:$HOME/.local/bin"
[ -f "$HOME/.zprofile" ] && source "$HOME/.zprofile" 2>/dev/null
[ -f "$HOME/.zshrc" ]   && source "$HOME/.zshrc"   2>/dev/null
CLAUDE=$(which claude 2>/dev/null || echo "claude")

# Build command to cd into Finder directory and launch Claude
CMD="cd $(printf '%q' \"$FINDER_PATH\") && $CLAUDE"

# Use osascript to open a new Terminal window and run the command
osascript -e "tell application \"Terminal\" to do script \"$CMD\""
osascript -e "tell application \"Terminal\" to activate"
