<div align="center">
  <h1>Claude macOS Launcher</h1>
  <p>Quickly launch Claude CLI from macOS Services.</p>
  <p><strong>English</strong> | <a href="./README.zh-CN.md">简体中文</a></p>
  <p><a href="https://github.com/alaliqing/claude-macos-launcher/blob/main/LICENSE"><img src="https://img.shields.io/github/license/alaliqing/claude-macos-launcher?color=6b7280" alt="License"></a> <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macos-18181b" alt="macOS"></a> <a href="https://github.com/anthropics/claude-code"><img src="https://img.shields.io/badge/claude%20cli-1f6feb" alt="Claude CLI"></a> <a href="https://github.com/alaliqing/claude-macos-launcher"><img src="https://img.shields.io/badge/finder%20services-5c6ac4" alt="Finder Services"></a></p>
  <p>Launch Claude from Finder context menus and keyboard shortcuts without manually opening Terminal or typing file references.</p>
</div>

---

## Features

- **Open Claude with Selection**: Right-click selected files and folders in Finder → open it from the Finder context menu → Auto-types `@file` and `@folder` references into Claude
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

These workflows are installed as macOS Finder Services. Depending on your macOS version and Finder configuration, they may appear under **Services** or **Quick Actions** in the Finder context menu.

### Open Claude with Selection

This Finder Service supports selected files, folders, or mixed selections:

**1. Single File**
- Right-click a file in Finder → choose **Open Claude with Selection** from the context menu
- Opens Claude and auto-types: `@filename.txt`
- Ready for you to add your prompt

**2. Multiple Files (2-10 items)**
- Select 2-10 files (Command+click to multi-select)
- Right-click in Finder → choose **Open Claude with Selection** from the context menu
- Opens Claude and auto-types: `@file1.txt @file2.txt @file3.txt`
- Perfect for: "Compare these files", "Summarize these documents"

**3. Single Folder**
- Right-click a folder in Finder → choose **Open Claude with Selection** from the context menu
- Opens Claude in that folder and includes a reference to the selected folder

**4. Multiple Folders**
- Select 2-10 folders in Finder
- Right-click in Finder → choose **Open Claude with Selection** from the context menu
- Opens Claude and stages the selected folder references together

**5. Mixed Files and Folders**
- Select files and folders together in Finder
- Right-click in Finder → choose **Open Claude with Selection** from the context menu
- Opens Claude and stages the full selection as context

**Not Supported:**
- More than 10 selected items (shows error)

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
rm -rf ~/Library/Services/"Open Claude with Selection.workflow"
rm -rf ~/Library/Services/"Open Claude Here.workflow"
/System/Library/CoreServices/pbs -flush
killall Finder
```

## How It Works

- Creates macOS Finder Services (Automator workflows) in `~/Library/Services/`
- Uses AppleScript to open Terminal and launch Claude CLI
- Waits for the new Terminal tab to report that Claude is running before auto-typing selection references
- Keyboard shortcut is automatically configured in system preferences
- Supports files and folders from different locations using smart absolute paths
- Preserves Chinese/Unicode characters in filenames

## Project Structure

```
claude-macos-launcher/
├── install.sh              # Bootstrap installer (downloads & installs)
├── uninstall.sh           # Removal script
├── src/
│   ├── workflow-selection.py   # Generates "Open Claude with Selection" workflow
│   └── workflow-here.py   # Generates "Open Claude Here" workflow
└── scripts/
    ├── open-with-selection.sh  # Logic for the Finder file/folder service
    └── open-here.sh       # Logic for the keyboard shortcut service
```

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

On first use, macOS may ask for Accessibility permission before it allows selection auto-typing.

If Claude opens but the selected references are not inserted:
- Open **System Settings** -> **Privacy & Security** -> **Accessibility**
- Enable **Finder**
- Run **Open Claude with Selection** again

This is usually a one-time macOS permission step.

### File auto-typing doesn't work

The script waits for the new Terminal tab to report that Claude is running before auto-typing. If your Mac is slow:
- Wait a bit longer (max 30 seconds timeout)
- If this is your first run, check the Accessibility steps above
- If it consistently fails after permissions are granted, you can manually type `@filename` or `@folder`

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
