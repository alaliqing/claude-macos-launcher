#!/bin/bash
# uninstall.sh - Remove Claude Finder Services from macOS
set -e

echo "==============================================================="
echo "Claude Finder Services Uninstaller"
echo "==============================================================="
echo ""

# Check if workflows exist
WORKFLOW1="$HOME/Library/Services/Open Claude with Selection.workflow"
WORKFLOW2="$HOME/Library/Services/Open Claude Here.workflow"
LEGACY_WORKFLOW="$HOME/Library/Services/Open Claude with File.workflow"

FOUND=0

if [ -d "$WORKFLOW1" ]; then
    echo "Found: Open Claude with Selection.workflow"
    FOUND=1
fi

if [ -d "$LEGACY_WORKFLOW" ]; then
    echo "Found: Open Claude with File.workflow"
    FOUND=1
fi

if [ -d "$WORKFLOW2" ]; then
    echo "Found: Open Claude Here.workflow"
    FOUND=1
fi

if [ $FOUND -eq 0 ]; then
    echo "No Claude Finder Services found. Nothing to uninstall."
    exit 0
fi

echo ""
if [ -t 0 ]; then
    read -p "Remove these Finder Services? (y/N) " -n 1 -r
elif [ -r /dev/tty ]; then
    read -p "Remove these Finder Services? (y/N) " -n 1 -r < /dev/tty
else
    echo "ERROR: Interactive confirmation requires a terminal."
    echo "Please download uninstall.sh and run it directly."
    exit 1
fi
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo "Removing Finder Services..."

# Remove workflows
if [ -d "$WORKFLOW1" ]; then
    rm -rf "$WORKFLOW1"
    echo "[OK] Removed: Open Claude with Selection"
fi

if [ -d "$LEGACY_WORKFLOW" ]; then
    rm -rf "$LEGACY_WORKFLOW"
    echo "[OK] Removed legacy workflow: Open Claude with File"
fi

if [ -d "$WORKFLOW2" ]; then
    rm -rf "$WORKFLOW2"
    echo "[OK] Removed: Open Claude Here"
fi

# Refresh services
echo ""
echo "Refreshing services..."
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
killall Finder 2>/dev/null || true

echo ""
echo "[SUCCESS] Uninstall complete!"
echo ""
echo "The Finder Services have been removed from your system."
echo ""
