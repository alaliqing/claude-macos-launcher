<div align="center">
  <h1>Claude macOS Launcher</h1>
  <p>在 macOS 上通过 Finder 服务从 Finder 启动 Claude CLI。</p>
  <p><a href="./README.md">English</a> | <strong>简体中文</strong></p>
  <p><a href="https://github.com/alaliqing/claude-macos-launcher/blob/main/LICENSE"><img src="https://img.shields.io/github/license/alaliqing/claude-macos-launcher?color=6b7280" alt="License"></a> <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/macos-18181b" alt="macOS"></a> <a href="https://github.com/anthropics/claude-code"><img src="https://img.shields.io/badge/claude%20cli-1f6feb" alt="Claude CLI"></a> <a href="https://github.com/alaliqing/claude-macos-launcher"><img src="https://img.shields.io/badge/finder%20services-5c6ac4" alt="Finder Services"></a></p>
  <p>无需手动打开 Terminal 或输入文件引用，直接从 Finder 右键菜单启动 Claude。</p>
</div>

---

## 功能

- **Open Claude with File**：在 Finder 中右键文件或文件夹，从上下文菜单打开该服务后，会自动将 `@filename` 输入到 Claude 中，方便你继续补充上下文
- **Open Claude Here**：在任意 Finder 窗口中按 `Command+Option+Shift+C`，直接在当前目录打开 Claude

## 环境要求

- macOS 10.15（Catalina）及以上
- 已安装 [Claude CLI](https://github.com/anthropics/claude-code)
- Python 3（macOS 10.15+ 默认已预装）

## 安装

### 一行安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/alaliqing/claude-macos-launcher/main/install.sh | bash
```

### 方式二：克隆仓库后安装

```bash
git clone https://github.com/alaliqing/claude-macos-launcher.git
cd claude-macos-launcher
bash install.sh
```

### 方式三：下载安装脚本后运行

```bash
curl -O https://raw.githubusercontent.com/alaliqing/claude-macos-launcher/main/install.sh
bash install.sh
```

## 使用方式

这些工作流会被安装为 macOS Finder 服务。根据你的 macOS 版本和 Finder 配置，它们可能显示在 Finder 右键菜单的 **Services** 或 **Quick Actions** 中。

### Open Claude with File

这个 Finder 服务支持以下三种场景：

**1. 单个文件**
- 在 Finder 中右键一个文件，选择 **Open Claude with File**
- 会打开 Claude，并自动输入：`@filename.txt`
- 接着你可以继续输入 prompt

**2. 多个文件（2-10 个）**
- 选中 2 到 10 个文件（可通过 Command+点选多选）
- 在 Finder 中右键，选择 **Open Claude with File**
- 会打开 Claude，并自动输入：`@file1.txt @file2.txt @file3.txt`
- 适合用于：比较文件、总结文档、做跨文件分析

**3. 单个文件夹**
- 在 Finder 中右键一个文件夹，选择 **Open Claude with File**
- 会在该文件夹目录中打开 Claude

**不支持的情况：**
- 超过 10 个文件（会提示错误）
- 多个文件夹（无法判断应打开哪个目录）
- 文件和文件夹混选（意图不明确）

### Open Claude Here

1. 打开任意 Finder 窗口
2. 按下 **Command+Option+Shift+C**
3. Terminal 会在当前目录中打开 Claude

## 自定义

### 修改快捷键

默认快捷键是 `Command+Option+Shift+C`。如果要修改：

1. 打开 **系统设置** -> **键盘** -> **键盘快捷键**
2. 在左侧点击 **服务**
3. 滚动到 **通用** 区域
4. 找到 **Open Claude Here**
5. 点击当前快捷键并按下你想要的新组合键

## 卸载

```bash
curl -fsSL https://raw.githubusercontent.com/alaliqing/claude-macos-launcher/main/uninstall.sh | bash
```

或者手动删除：

```bash
rm -rf ~/Library/Services/"Open Claude with File.workflow"
rm -rf ~/Library/Services/"Open Claude Here.workflow"
/System/Library/CoreServices/pbs -flush
killall Finder
```

## 实现原理

- 在 `~/Library/Services/` 中创建 macOS Finder 服务（Automator workflows）
- 使用 AppleScript 打开 Terminal 并启动 Claude CLI
- 等待新建的 Terminal 标签页报告 Claude 已启动后，再自动输入文件引用
- 自动在系统设置中配置快捷键
- 支持跨目录文件，并自动处理绝对路径
- 支持中文和其他 Unicode 文件名

## 项目结构

```text
claude-macos-launcher/
├── install.sh              # 安装入口脚本（下载并安装）
├── uninstall.sh            # 卸载脚本
├── src/
│   ├── workflow-file.py    # 生成 “Open Claude with File” 工作流
│   └── workflow-here.py    # 生成 “Open Claude Here” 工作流
└── scripts/
    ├── open-with-file.sh   # Finder 文件/文件夹服务逻辑
    └── open-here.sh        # 键盘快捷键服务逻辑
```

## 故障排查

### 快捷键无效

- 尝试退出登录后重新登录
- 或者到系统设置中手动重新设置快捷键（见上面的“自定义”）

### 提示 “Claude not found”

确认 Claude CLI 已安装：

```bash
npm install -g @anthropic-ai/claude-code
```

### 辅助功能权限错误

首次使用时，macOS 可能会要求授予辅助功能权限，之后才允许自动输入文件引用。

如果 Claude 已经打开，但文件名没有自动输入：
- 打开 **系统设置** -> **隐私与安全性** -> **辅助功能**
- 启用 **Finder**
- 再次运行 **Open Claude with File**

这通常只是一次性的 macOS 权限步骤。

### 文件自动输入失败

脚本会等待新建的 Terminal 标签页报告 Claude 已启动，然后再自动输入文件引用。如果你的 Mac 较慢：
- 可以多等一会儿（最长约 30 秒超时）
- 如果是第一次运行，先检查上面的辅助功能权限步骤
- 如果在授权后仍持续失败，可以手动输入 `@filename`

## 参与贡献

欢迎通过以下方式参与：

- 提交 bug
- 提出功能建议
- 提交 pull request

## License

MIT License，详见 [LICENSE](LICENSE) 文件。

## 作者

Created by [@alaliqing](https://github.com/alaliqing)

## 致谢

- 基于 Anthropic 的 [Claude Code](https://github.com/anthropics/claude-code)
- 灵感来自于希望更快地从 Finder 使用 Claude CLI
