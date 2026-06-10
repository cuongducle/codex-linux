# Title: I built native .deb and AppImage packages for Codex Desktop on Linux — with Wayland support, auto-updates, and an APT repo

OpenAI's Codex Desktop only ships for macOS, but I've been running it natively on Linux by rebuilding the upstream Electron app from source. Here's what the project does:

**What it is:** Unofficial packaging that takes the official macOS build, patches it for Linux, and ships it as a native `.deb` (Ubuntu/Debian) and `.AppImage` (any distro).

**Key features:**
- 🖥️ Native `.deb` and `.AppImage` packaging
- 🌐 Wayland support with auto-detection (falls back to X11)
- 🔄 Auto-updates via daily upstream monitoring (CI checks ETag every day, auto-tags new releases)
- 📦 One-line APT install: `curl -fsSL https://cuongducle.github.io/codex-linux/install.sh | sudo bash`
- 🛡️ Chromium sandbox handling (setuid + AppArmor userns profile for Ubuntu 24.04+)
- 🔧 Built-in `codex-desktop --doctor` for troubleshooting
- 🏗️ Supports both amd64 and arm64

**How it works under the hood:**
1. Downloads the upstream macOS `.dmg`
2. Extracts `app.asar` and resources
3. Rebuilds native modules (`better-sqlite3`, `node-pty`) for Linux
4. Applies Linux-specific patches (Wayland, sandbox, sidebar rendering)
5. Packages via electron-builder

**Install:**
```bash
# Quick install (Ubuntu/Debian)
curl -fsSL https://cuongducle.github.io/codex-linux/install.sh | sudo bash

# Or add APT repo for auto-updates
echo "deb [trusted=yes] https://cuongducle.github.io/codex-linux/ stable main" \
  | sudo tee /etc/apt/sources.list.d/codex-desktop.list
sudo apt update && sudo apt install codex-desktop
```

**Repo:** https://github.com/cuongducle/codex-linux

This is an unofficial build — no Codex source code is redistributed, only packaging scripts. Would love feedback from the Linux community on distro compatibility and any issues!
