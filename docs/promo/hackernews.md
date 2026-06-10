# Show HN: Codex Desktop for Linux – Native .deb/AppImage with Wayland, auto-updates, and APT repo

OpenAI's Codex Desktop (AI coding agent) only ships for macOS. I built an unofficial packaging pipeline that makes it run natively on Linux.

The project downloads the upstream macOS `.dmg`, extracts the Electron app, rebuilds native modules (`better-sqlite3`, `node-pty`) from source for Linux, applies Linux-specific patches, and packages as `.deb` (Debian/Ubuntu) and `.AppImage` (any distro).

Notable bits:
- **Automated upstream tracking**: CI runs daily, detects new versions via ETag, auto-builds and publishes releases + updates the APT repo
- **Wayland support**: Auto-detects `WAYLAND_DISPLAY`, uses native Wayland with window decorations, falls back to X11
- **Sandbox handling**: `chrome-sandbox` setuid + AppArmor `userns` profile (Ubuntu 24.04+ blocks unprivileged user namespaces by default)
- **System integration**: Desktop entry, Freedesktop icon set (16→512px), AppStream metainfo, `x-scheme-handler/codex` deep-linking
- **Troubleshooting**: Built-in `codex-desktop --doctor` that prints display server, GPU, sandbox status, Electron version
- **Crash recovery**: Auto-cleans stale `SingletonLock` symlinks on startup

Install (one-line):
```
curl -fsSL https://cuongducle.github.io/codex-linux/install.sh | sudo bash
```

Repo: https://github.com/cuongducle/codex-linux

This is an unofficial project — it doesn't redistribute Codex source code, only packaging scripts that build from the publicly available upstream app. Happy to answer questions about the packaging approach!
