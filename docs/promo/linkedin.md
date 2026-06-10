# LinkedIn Post

I built an unofficial Linux packaging pipeline for OpenAI's Codex Desktop — making it run natively on Ubuntu, Debian, and any Linux distro.

The challenge: Codex Desktop is an Electron app that only ships for macOS. Getting it to run on Linux required:
• Rebuilding native modules (better-sqlite3, node-pty) from source
• Patching Electron for Wayland support
• Handling Chromium sandbox permissions (setuid + AppArmor)
• Working around Ubuntu 24.04+ blocking unprivileged user namespaces

The result:
✅ Native .deb and .AppImage packages
✅ Wayland auto-detection
✅ Automated upstream tracking (daily CI → auto-release)
✅ APT repository for `apt upgrade`
✅ Built-in `codex-desktop --doctor` diagnostics
✅ amd64 + arm64 support

One-line install:
curl -fsSL https://cuongducle.github.io/codex-linux/install.sh | sudo bash

Repository: https://github.com/cuongducle/codex-linux

This was a fun exercise in Electron packaging, Linux system integration, and CI/CD automation. If you're working on similar projects, happy to share more details about the approach.

#OpenAI #Codex #Linux #Ubuntu #Debian #Electron #Wayland #DevTools #OpenSource #Packaging
