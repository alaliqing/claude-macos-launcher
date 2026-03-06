# Claude macOS Launcher

Quick Actions for launching Claude CLI from Finder on macOS.

## Features

- **Open Claude with File**: Right-click any file or folder in Finder → Quick Actions → Auto-types `@filename` into Claude (ready for you to add context)
- **Open Claude Here**: Press `Command+Option+Shift+C` in any Finder window → Opens Claude in that directory

## Requirements

- macOS 10.15 (Catalina) or later
- [Claude CLI](https://github.com/anthropics/claude-code) installed
- Python 3 (pre-installed on macOS 10.15+)

## Installation

### One-line install (recommended):

```bash
curl -fsSL https://raw.githubusercontent.com/alaliqing/claude-macos-launcher/main/install.sh | bash
```

### Alternative: Clone and install

```bash
git clone https://github.com/alaliqing/claude-macos-launcher.git
cd claude-macos-launcher
bash install.sh
```

### Alternative: Download and run

```bash
curl -O https://raw.githubusercontent.com/alaliqing/claude-macos-launcher/main/install.sh
bash install.sh
```

## Usage

### Open Claude with File

This Quick Action supports three scenarios:

**1. Single File**
- Right-click a file → Quick Actions → Open Claude with File
- Opens Claude and auto-types: `@filename.txt `
- Ready for you to add your prompt

**2. Multiple Files (2-10 files)**
- Select 2-10 files (Command+click to multi-select)
- Right-click → Quick Actions → Open Claude with File
- Opens Claude and auto-types: `@file1.txt @file2.txt @file3.txt `
- Perfect for: "Compare these files", "Summarize these documents"

**3. Single Folder**
- Right-click a folder → Quick Actions → Open Claude with File
- Opens Claude in that folder's directory

**Not Supported:**
- More than 10 files (shows error)
- Multiple folders (ambiguous which to open)
- Mixed files and folders (unclear intent)

### Open Claude Here

1. Open any Finder window
2. Press **Command+Option+Shift+C**
3. Terminal opens with Claude in that directory

## Customization

### Change Keyboard Shortcut

The default keyboard shortcut is `Command+Option+Shift+C`. To change it:

1. Open **System Settings** → **Keyboard** → **Keyboard Shortcuts**
2. Click **Services** in the left sidebar
3. Scroll to **General** section
4. Find **Open Claude Here**
5. Click the shortcut and press your desired key combination

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/alaliqing/claude-macos-launcher/main/uninstall.sh | bash
```

Or manually remove:

```bash
rm -rf ~/Library/Services/"Open Claude with File.workflow"
rm -rf ~/Library/Services/"Open Claude Here.workflow"
/System/Library/CoreServices/pbs -flush
killall Finder
```

## How It Works

- Creates macOS Quick Actions (Automator workflows) in `~/Library/Services/`
- Uses AppleScript to open Terminal and launch Claude CLI
- Smart process detection waits for Claude to start before auto-typing filename
- Keyboard shortcut is automatically configured in system preferences

## Troubleshooting

### Keyboard shortcut doesn't work

- Try logging out and logging back in
- Or manually set it in System Settings (see Customization section above)

### "Claude not found" error

Make sure Claude CLI is installed:

```bash
npm install -g @anthropic-ai/claude-code
```

### Accessibility permission error

On first use, macOS will ask for Accessibility permissions for keystroke automation. Click "Open System Settings" and grant permission.

### File auto-typing doesn't work

The script waits for Claude process to start. If your Mac is slow:
- Wait a bit longer (max 6 seconds timeout)
- If it consistently fails, you can manually type `@filename`

## Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest features
- Submit pull requests

## License

MIT License - see [LICENSE](LICENSE) file for details

## Author

Created by [@alaliqing](https://github.com/alaliqing)

## Acknowledgments

- Built for [Claude Code](https://github.com/anthropics/claude-code) by Anthropic
- Inspired by the need for faster Claude CLI access from Finder
