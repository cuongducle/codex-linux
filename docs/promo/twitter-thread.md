🧵 Thread: I built Codex Desktop for Linux — here's how it works 👇

OpenAI's Codex Desktop only runs on macOS. No official Linux release.

So I built an unofficial packaging pipeline that makes it run natively on any Linux distro — with Wayland, auto-updates, and a proper APT repository.

Here's what it does 🧵

1/ It downloads the upstream macOS .dmg, extracts the Electron app, rebuilds native modules (better-sqlite3, node-pty) from source for Linux, and packages as .deb + AppImage.

No Codex source code is redistributed — only packaging scripts.

2/ Wayland support works out of the box. It auto-detects WAYLAND_DISPLAY, uses native Wayland with window decorations, and falls back to X11 if needed.

Also handles Chromium sandbox via setuid + AppArmor userns profile (Ubuntu 24.04+).

3/ Auto-updates are fully automated:

• CI runs daily
• Checks upstream via ETag (no redundant downloads)
• Auto-tags and publishes new releases
• Updates the APT repo on GitHub Pages

You just run `sudo apt upgrade` to update.

4/ One-line install:

curl -fsSL https://cuongducle.github.io/codex-linux/install.sh | sudo bash

Or add the APT repo:
echo "deb [trusted=yes] https://cuongducle.github.io/codex-linux/ stable main" | sudo tee /etc/apt/sources.list.d/codex-desktop.list
sudo apt update && sudo apt install codex-desktop

5/ Built-in diagnostics:
`codex-desktop --doctor`

Prints display server, GPU, sandbox status, CLI resolution, Electron version — the first thing to run when something misbehaves.

6/ Supports amd64 + arm64. AppImage for any distro, .deb for Ubuntu/Debian 22.04+.

Full repo: https://github.com/cuongducle/codex-linux

Unofficial project, not affiliated with OpenAI. Built for the Linux community 🐧

#Linux #OpenAI #Codex #AI #DevTools #Electron #Ubuntu #Debian #Wayland #OpenSource
