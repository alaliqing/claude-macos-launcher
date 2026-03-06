#!/bin/bash
# install-claude-action.sh
# Creates two ways to launch Claude with AUTOMATIC keyboard shortcut setup:
# 1. "Open Claude with File" - Right-click file/folder (Quick Action)
# 2. "Open Claude Here" - Keyboard shortcut Command+Option+Shift+C
set -e

echo "==============================================================="
echo "Claude Quick Actions Installer"
echo "==============================================================="
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
    CLAUDE_PATH=$(which claude)
    echo "[OK] Found at $CLAUDE_PATH"
else
    echo "[WARN] Not found"
    echo ""
    echo "WARNING: Claude CLI is not installed."
    echo "The Quick Actions will be installed, but won't work until you install Claude CLI."
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
echo "Installing Claude Quick Actions..."
echo ""

# ============================================================================
# ACTION 1: Open Claude with File (file/folder context menu)
# ============================================================================
CONTENTS_DIR1="$HOME/Library/Services/Open Claude with File.workflow/Contents"
rm -rf "$HOME/Library/Services/Open Claude with File.workflow"
mkdir -p "$CONTENTS_DIR1"

# Info.plist for file/folder action
python3 -c "
import plistlib, os
p = {'NSServices': [{'NSMenuItem': {'default': 'Open Claude with File'}, 'NSMessage': 'runWorkflowAsService', 'NSRequiredContext': {'NSApplicationIdentifier': 'com.apple.finder'}, 'NSSendFileTypes': ['public.item', 'public.folder']}]}
with open(os.path.expanduser('$CONTENTS_DIR1/Info.plist'), 'wb') as f:
    plistlib.dump(p, f)
"

# document.wflow for file/folder action
python3 << 'PYEOF1'
import plistlib, uuid, os

contents = os.path.expanduser('~') + '/Library/Services/Open Claude with File.workflow/Contents'

lines = [
    '#!/bin/bash',
    'F=$(cat)',
    '[ -z "$F" ] && exit 0',
    # Resolve the claude binary location
    'export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin:$HOME/.npm-global/bin:$HOME/.local/bin"',
    '[ -f "$HOME/.zprofile" ] && source "$HOME/.zprofile" 2>/dev/null',
    '[ -f "$HOME/.zshrc" ]   && source "$HOME/.zshrc"   2>/dev/null',
    'CLAUDE=$(which claude 2>/dev/null || echo "claude")',
    # Build cd + claude command
    'if [ -d "$F" ]; then',
    '  # For directories, just cd into them and launch Claude',
    '  CMD="cd $(printf \'%q\' \"$F\") && $CLAUDE"',
    '  osascript -e "tell application \\"Terminal\\" to do script \\"$CMD\\""',
    '  osascript -e "tell application \\"Terminal\\" to activate"',
    'else',
    '  # For files, use AppleScript to auto-type @filename',
    '  FILENAME=$(basename "$F")',
    '  DIRPATH=$(dirname "$F")',
    '  CMD="cd $(printf \'%q\' \"$DIRPATH\") && $CLAUDE"',
    '  # Launch Claude in Terminal',
    '  osascript -e "tell application \\"Terminal\\" to do script \\"$CMD\\""',
    '  osascript -e "tell application \\"Terminal\\" to activate"',
    '  # Wait for Claude to initialize, then auto-type the @filename',
    '  sleep 2',
    '  osascript -e "tell application \\"System Events\\" to keystroke \\"@$(printf \'%q\' \"$FILENAME\")\\""',
    'fi',
]

script = '\n'.join(lines) + '\n'
assert '\r' not in script

doc = {
    'AMApplicationBuild': '523',
    'AMApplicationVersion': '2.10',
    'AMDocumentVersion': '2',
    'actions': [{
        'action': {
            'AMAccepts': {'Container': 'List', 'Optional': True, 'Types': ['com.apple.cocoa.path']},
            'AMProvides': {'Container': 'List', 'Types': ['com.apple.cocoa.path']},
            'ActionBundlePath': '/System/Library/Automator/Run Shell Script.action',
            'ActionName': 'Run Shell Script',
            'ActionParameters': {
                'COMMAND_STRING': script,
                'CheckedForUserDefaultShell': True,
                'inputMethod': 0,
                'shell': '/bin/bash',
                'source': '',
            },
            'BundleIdentifier': 'com.apple.RunShellScript',
            'CFBundleVersion': '2.0.3',
            'CanShowSelectedItemsWhenRun': False,
            'CanShowWhenRun': True,
            'Category': ['AMCategoryUtilities'],
            'Class Name': 'RunShellScriptAction',
            'InputUUID': str(uuid.uuid4()).upper(),
            'OutputUUID': str(uuid.uuid4()).upper(),
            'UUID': str(uuid.uuid4()).upper(),
            'UnlocalizedApplications': ['Automator'],
            'isViewVisible': True,
            'location': '309.500000:253.000000',
            'nibPath': '/System/Library/Automator/Run Shell Script.action/Contents/Resources/en.lproj/main.nib',
        },
        'isViewVisible': True,
    }],
    'connectors': {},
    'workflowMetaData': {
        'workflowTypeIdentifier': 'com.apple.Automator.servicesMenu',
        'serviceInputTypeIdentifier': 'com.apple.Automator.fileSystemObject',
        'serviceOutputTypeIdentifier': 'com.apple.Automator.nothing',
        'serviceProcessesInput': False,
        'serviceApplicationBundleID': 'com.apple.finder',
    },
}

out = os.path.join(contents, 'document.wflow')
with open(out, 'wb') as f:
    plistlib.dump(doc, f, fmt=plistlib.FMT_BINARY)
print('Action 1 created: Open Claude with File')
PYEOF1

chmod -R 755 "$HOME/Library/Services/Open Claude with File.workflow"

# ============================================================================
# ACTION 2: Open Claude Here (global service with keyboard shortcut)
# ============================================================================
CONTENTS_DIR2="$HOME/Library/Services/Open Claude Here.workflow/Contents"
rm -rf "$HOME/Library/Services/Open Claude Here.workflow"
mkdir -p "$CONTENTS_DIR2"

# Info.plist for "Open Claude Here" - accepts NO input, works globally
python3 -c "
import plistlib, os
p = {'NSServices': [{'NSMenuItem': {'default': 'Open Claude Here'}, 'NSMessage': 'runWorkflowAsService'}]}
with open(os.path.expanduser('$CONTENTS_DIR2/Info.plist'), 'wb') as f:
    plistlib.dump(p, f)
"

# document.wflow for "Open Claude Here"
python3 << 'PYEOF2'
import plistlib, uuid, os

contents = os.path.expanduser('~') + '/Library/Services/Open Claude Here.workflow/Contents'

lines = [
    '#!/bin/bash',
    # Get current Finder window path using AppleScript
    'FINDER_PATH=$(osascript -e "tell application \\"Finder\\" to if (count of Finder windows) > 0 then get POSIX path of (target of front Finder window as alias)" 2>/dev/null)',
    # Fallback to home directory if no Finder window is open
    '[ -z "$FINDER_PATH" ] && FINDER_PATH="$HOME"',
    # Resolve the claude binary location
    'export PATH="$PATH:/usr/local/bin:/opt/homebrew/bin:$HOME/.npm-global/bin:$HOME/.local/bin"',
    '[ -f "$HOME/.zprofile" ] && source "$HOME/.zprofile" 2>/dev/null',
    '[ -f "$HOME/.zshrc" ]   && source "$HOME/.zshrc"   2>/dev/null',
    'CLAUDE=$(which claude 2>/dev/null || echo "claude")',
    # Build command to cd into Finder directory and launch Claude
    'CMD="cd $(printf \'%q\' \\"$FINDER_PATH\\") && $CLAUDE"',
    # Use osascript to open a new Terminal window and run the command
    'osascript -e "tell application \\"Terminal\\" to do script \\"$CMD\\""',
    'osascript -e "tell application \\"Terminal\\" to activate"',
]

script = '\n'.join(lines) + '\n'
assert '\r' not in script

doc = {
    'AMApplicationBuild': '523',
    'AMApplicationVersion': '2.10',
    'AMDocumentVersion': '2',
    'actions': [{
        'action': {
            'AMAccepts': {'Container': 'List', 'Optional': True, 'Types': ['com.apple.cocoa.string']},
            'AMActionVersion': '2.0.3',
            'AMProvides': {'Container': 'List', 'Types': ['com.apple.cocoa.string']},
            'ActionBundlePath': '/System/Library/Automator/Run Shell Script.action',
            'ActionName': 'Run Shell Script',
            'ActionParameters': {
                'COMMAND_STRING': script,
                'CheckedForUserDefaultShell': True,
                'inputMethod': 1,  # No input
                'shell': '/bin/bash',
                'source': '',
            },
            'BundleIdentifier': 'com.apple.RunShellScript',
            'CFBundleVersion': '2.0.3',
            'CanShowSelectedItemsWhenRun': False,
            'CanShowWhenRun': True,
            'Category': ['AMCategoryUtilities'],
            'Class Name': 'RunShellScriptAction',
            'InputUUID': str(uuid.uuid4()).upper(),
            'OutputUUID': str(uuid.uuid4()).upper(),
            'UUID': str(uuid.uuid4()).upper(),
            'UnlocalizedApplications': ['Automator'],
            'isViewVisible': True,
            'location': '309.500000:253.000000',
            'nibPath': '/System/Library/Automator/Run Shell Script.action/Contents/Resources/en.lproj/main.nib',
        },
        'isViewVisible': True,
    }],
    'connectors': {},
    'workflowMetaData': {
        'workflowTypeIdentifier': 'com.apple.Automator.servicesMenu',
        'serviceInputTypeIdentifier': 'com.apple.Automator.nothing',
        'serviceOutputTypeIdentifier': 'com.apple.Automator.nothing',
        'serviceApplicationBundleID': 'com.apple.finder',
    },
}

out = os.path.join(contents, 'document.wflow')
with open(out, 'wb') as f:
    plistlib.dump(doc, f, fmt=plistlib.FMT_BINARY)
print('Action 2 created: Open Claude Here')
PYEOF2

chmod -R 755 "$HOME/Library/Services/Open Claude Here.workflow"

# ============================================================================
# Refresh Services
# ============================================================================
/System/Library/CoreServices/pbs -flush 2>/dev/null || true

# ============================================================================
# AUTOMATIC KEYBOARD SHORTCUT SETUP
# ============================================================================
echo ""
echo "Setting up keyboard shortcut (Command+Option+Shift+C) for 'Open Claude Here'..."

# Get the service bundle identifier
SERVICE_NAME="Open Claude Here"

# Read existing keyboard shortcuts plist
PLIST_PATH="$HOME/Library/Preferences/pbs.plist"

# Create or update the keyboard shortcut using defaults command
# The format is: NSServicesStatus -> service identifier -> key_equivalent
# Key combination: ⌘⌥⇧C = Cmd(@) + Option(~) + Shift($) + C
SHORTCUT_KEY="@~\$c"

python3 << 'PYEOF3'
import plistlib
import os
import subprocess

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
    # Format: (null) - Open Claude Here - runWorkflowAsService
    service_key = '(null) - Open Claude Here - runWorkflowAsService'
    data['NSServicesStatus'][service_key] = {}

# Set the keyboard shortcut
if 'key_equivalent' not in data['NSServicesStatus'][service_key]:
    data['NSServicesStatus'][service_key]['key_equivalent'] = '@~$c'
else:
    data['NSServicesStatus'][service_key]['key_equivalent'] = '@~$c'

# Enable the service
data['NSServicesStatus'][service_key]['enabled_context_menu'] = True
data['NSServicesStatus'][service_key]['enabled_services_menu'] = True

# Write back
with open(plist_path, 'wb') as f:
    plistlib.dump(data, f)

print("Keyboard shortcut configured in pbs.plist")
PYEOF3

# Restart the services daemon to apply changes
killall Finder 2>/dev/null || true
killall cfprefsd 2>/dev/null || true

echo ""
echo "[SUCCESS] Installation complete!"
echo ""
echo "==============================================================="
echo "Two Quick Actions have been installed:"
echo "==============================================================="
echo ""
echo "1. 'Open Claude with File'"
echo "   -> Right-click any file/folder -> Quick Actions"
echo "   -> Opens Claude with file staged (NOT auto-sent)"
echo ""
echo "2. 'Open Claude Here'"
echo "   -> Keyboard shortcut: Command+Option+Shift+C"
echo "   -> Opens Claude in current Finder directory"
echo ""
echo "==============================================================="
echo "Usage:"
echo "==============================================================="
echo ""
echo "- Right-click file/folder -> 'Open Claude with File'"
echo "- In any Finder window, press Command+Option+Shift+C -> Claude opens there!"
echo ""
echo "Note: If keyboard shortcut doesn't work immediately:"
echo "  1. Log out and log back in (or restart)"
echo "  2. Or manually set it in: System Settings -> Keyboard ->"
echo "     Keyboard Shortcuts -> Services -> General -> Open Claude Here"
echo ""
echo "==============================================================="
echo ""
