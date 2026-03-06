#!/bin/bash
# install-claude-action-v3.sh
# Creates two ways to launch Claude with AUTOMATIC keyboard shortcut setup:
# 1. "Open Claude with File" - Right-click file/folder (Quick Action)
# 2. "Open Claude Here" - Keyboard shortcut ⌃⌥⌘C (Ctrl+Option+Cmd+C)
set -e

echo "Installing enhanced Claude Quick Actions..."

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
    # Build cd + claude command - MODIFIED to not auto-send
    'if [ -d "$F" ]; then',
    '  # For directories, just cd into them',
    '  CMD="cd $(printf \'%q\' \"$F\") && $CLAUDE"',
    'else',
    '  # For files, cd to directory and print @file instruction (not auto-send)',
    '  FILENAME=$(basename "$F")',
    '  DIRPATH=$(dirname "$F")',
    '  CMD="cd $(printf \'%q\' \"$DIRPATH\") && echo \'File ready: @$(printf \'%q\' \"$FILENAME\")\' && $CLAUDE"',
    'fi',
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
echo "Setting up keyboard shortcut (⌥⇧C) for 'Open Claude Here'..."

# Get the service bundle identifier
SERVICE_NAME="Open Claude Here"

# Read existing keyboard shortcuts plist
PLIST_PATH="$HOME/Library/Preferences/pbs.plist"

# Create or update the keyboard shortcut using defaults command
# The format is: NSServicesStatus -> service identifier -> key_equivalent
# Key combination: ⌥⇧C = Option(~) + Shift($) + C
SHORTCUT_KEY="~\$c"

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
    data['NSServicesStatus'][service_key]['key_equivalent'] = '~$c'
else:
    data['NSServicesStatus'][service_key]['key_equivalent'] = '~$c'

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
echo "✓ Installation complete!"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "Two Quick Actions have been installed:"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "1. 'Open Claude with File'"
echo "   → Right-click any file/folder → Quick Actions"
echo "   → Opens Claude with file staged (NOT auto-sent)"
echo ""
echo "2. 'Open Claude Here'"
echo "   → Keyboard shortcut: ⌥⇧C (Option+Shift+C)"
echo "   → Opens Claude in current Finder directory"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "Usage:"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "• Right-click file/folder → 'Open Claude with File'"
echo "• In any Finder window, press ⌥⇧C → Claude opens there!"
echo ""
echo "Note: If keyboard shortcut doesn't work immediately:"
echo "  1. Log out and log back in (or restart)"
echo "  2. Or manually set it in: System Settings → Keyboard →"
echo "     Keyboard Shortcuts → Services → General → Open Claude Here"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
