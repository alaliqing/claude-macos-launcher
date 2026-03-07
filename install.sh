#!/bin/bash
# Claude macOS Launcher - Bootstrap Installer
# https://github.com/alaliqing/claude-macos-launcher
set -e

REPO_URL="https://raw.githubusercontent.com/alaliqing/claude-macos-launcher/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==============================================================="
echo "Claude Finder Services Installer"
echo "==============================================================="
echo ""

# ============================================================================
# DETECT INSTALL MODE
# ============================================================================
if [ "$SCRIPT_DIR" = "/dev/fd" ] || [ ! -f "$SCRIPT_DIR/src/workflow-file.py" ]; then
    # Running via curl | bash - need to download files
    INSTALL_MODE="download"
    TMPDIR=$(mktemp -d)
    WORK_DIR="$TMPDIR"
    echo "[INFO] Running in download mode (one-liner install)"
else
    # Running from cloned repo
    INSTALL_MODE="local"
    WORK_DIR="$SCRIPT_DIR"
    echo "[INFO] Running in local mode (git clone)"
fi

echo ""

# ============================================================================
# PRE-FLIGHT CHECKS
# ============================================================================
echo "Running pre-flight checks..."
echo ""

ERRORS=0

# Check 1: Python 3
echo -n "Checking Python 3... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    echo "[OK] Found (version $PYTHON_VERSION)"
else
    echo "[FAIL] Not found"
    echo ""
    echo "ERROR: Python 3 is required but not found."
    echo "Please install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    echo ""
    ERRORS=$((ERRORS + 1))
fi

# Check 2: Python standard libraries
echo -n "Checking Python libraries... "
if python3 -c "import plistlib, uuid, os" 2>/dev/null; then
    echo "[OK] All required libraries available"
else
    echo "[FAIL] Missing required libraries"
    ERRORS=$((ERRORS + 1))
fi

# Check 3: Claude CLI
echo -n "Checking Claude CLI... "
export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin:$HOME/.npm-global/bin:$HOME/.local/bin"

if command -v claude &> /dev/null; then
    CLAUDE_PATH=$(command -v claude)
    echo "[OK] Found at $CLAUDE_PATH"
else
    echo "[WARN] Not found"
    echo ""
    echo "WARNING: Claude CLI is not installed."
    echo "The Finder Services will be installed, but won't work until you install Claude CLI."
    echo ""
    echo "To install Claude CLI, visit:"
    echo "  https://github.com/anthropics/claude-code"
    echo ""
    echo "Or install via npm:"
    echo "  npm install -g @anthropic-ai/claude-code"
    echo ""
    read -p "Continue installation anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
fi

# Check 4: macOS version
echo -n "Checking macOS version... "
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo $MACOS_VERSION | cut -d. -f1)
MACOS_MINOR=$(echo $MACOS_VERSION | cut -d. -f2)

if [ "$MACOS_MAJOR" -lt 10 ] || ([ "$MACOS_MAJOR" -eq 10 ] && [ "$MACOS_MINOR" -lt 15 ]); then
    echo "[WARN] $MACOS_VERSION (may not be compatible)"
    echo ""
    echo "WARNING: Your macOS version may not be compatible."
    echo "This script requires macOS 10.15 (Catalina) or later."
    echo "Your version: $MACOS_VERSION"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
else
    echo "[OK] $MACOS_VERSION"
fi

# Check 5: Required system commands
echo -n "Checking system commands... "
MISSING_CMDS=""
for cmd in osascript chmod mkdir rm killall defaults; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_CMDS="$MISSING_CMDS $cmd"
    fi
done

if [ -z "$MISSING_CMDS" ]; then
    echo "[OK] All required commands available"
else
    echo "[FAIL] Missing commands:$MISSING_CMDS"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# Exit if critical errors found
if [ $ERRORS -gt 0 ]; then
    echo "[ERROR] Installation cannot continue due to missing dependencies."
    echo "Please fix the errors above and try again."
    exit 1
fi

echo "[SUCCESS] All pre-flight checks passed!"
echo ""

# ============================================================================
# DOWNLOAD FILES (if in download mode)
# ============================================================================
if [ "$INSTALL_MODE" = "download" ]; then
    echo "Downloading components..."
    cd "$WORK_DIR"

    mkdir -p src scripts

    curl -fsSL "$REPO_URL/src/workflow-file.py" -o src/workflow-file.py || {
        echo "[ERROR] Failed to download workflow-file.py"
        exit 1
    }

    curl -fsSL "$REPO_URL/src/workflow-here.py" -o src/workflow-here.py || {
        echo "[ERROR] Failed to download workflow-here.py"
        exit 1
    }

    curl -fsSL "$REPO_URL/scripts/open-with-file.sh" -o scripts/open-with-file.sh || {
        echo "[ERROR] Failed to download open-with-file.sh"
        exit 1
    }

    curl -fsSL "$REPO_URL/scripts/open-here.sh" -o scripts/open-here.sh || {
        echo "[ERROR] Failed to download open-here.sh"
        exit 1
    }

    echo "[OK] All components downloaded"
    echo ""
fi

# ============================================================================
# INSTALL WORKFLOWS
# ============================================================================
echo "Installing Claude Finder Services..."
echo ""

# Install "Open Claude with File"
python3 "$WORK_DIR/src/workflow-file.py" "$WORK_DIR/scripts/open-with-file.sh"

# Install "Open Claude Here"
python3 "$WORK_DIR/src/workflow-here.py" "$WORK_DIR/scripts/open-here.sh"

# ============================================================================
# SETUP KEYBOARD SHORTCUT
# ============================================================================
echo ""
echo "Setting up keyboard shortcut (Command+Option+Shift+C) for 'Open Claude Here'..."

python3 << 'PYEOF'
import plistlib
import os

plist_path = os.path.expanduser('~/Library/Preferences/pbs.plist')

# Try to read existing plist
try:
    with open(plist_path, 'rb') as f:
        data = plistlib.load(f)
except FileNotFoundError:
    data = {}

# Initialize NSServicesStatus if it doesn't exist
if 'NSServicesStatus' not in data:
    data['NSServicesStatus'] = {}

# Find the service key (it includes bundle path)
service_key = None
for key in data.get('NSServicesStatus', {}):
    if 'Open Claude Here' in key:
        service_key = key
        break

if not service_key:
    # Create the key format that macOS uses
    service_key = '(null) - Open Claude Here - runWorkflowAsService'
    data['NSServicesStatus'][service_key] = {}

# Set the keyboard shortcut: Command+Option+Shift+C
data['NSServicesStatus'][service_key]['key_equivalent'] = '@~$c'

# Enable the service
data['NSServicesStatus'][service_key]['enabled_context_menu'] = True
data['NSServicesStatus'][service_key]['enabled_services_menu'] = True

# Write back
with open(plist_path, 'wb') as f:
    plistlib.dump(data, f)

print("[OK] Keyboard shortcut configured")
PYEOF

# ============================================================================
# REFRESH SERVICES
# ============================================================================
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
killall Finder 2>/dev/null || true
killall cfprefsd 2>/dev/null || true

# ============================================================================
# CLEANUP (if in download mode)
# ============================================================================
if [ "$INSTALL_MODE" = "download" ]; then
    cd - > /dev/null
    rm -rf "$TMPDIR"
fi

# ============================================================================
# SUCCESS MESSAGE
# ============================================================================
echo ""
echo "[SUCCESS] Installation complete!"
echo ""
echo "==============================================================="
echo "Two Finder Services have been installed:"
echo "==============================================================="
echo ""
echo "1. 'Open Claude with File'"
echo "   -> Right-click any file/folder in Finder -> context menu"
echo "   -> Opens Claude with file staged"
echo ""
echo "2. 'Open Claude Here'"
echo "   -> Keyboard shortcut: Command+Option+Shift+C"
echo "   -> Opens Claude in current Finder directory"
echo ""
echo "==============================================================="
echo "First use note:"
echo "==============================================================="
echo ""
echo "- The first time you use 'Open Claude with File', macOS may ask for Accessibility permission"
echo "- If file auto-typing fails, open System Settings -> Privacy & Security -> Accessibility"
echo "- Enable Finder, then run 'Open Claude with File' again"
echo ""
echo "==============================================================="
echo "Usage:"
echo "==============================================================="
echo ""
echo "- Right-click a file/folder in Finder -> 'Open Claude with File'"
echo "- In any Finder window, press Command+Option+Shift+C -> Claude opens there!"
echo ""
echo "==============================================================="
echo ""
