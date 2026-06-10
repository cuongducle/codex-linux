# Title: Show: Codex Desktop for Linux — packaging OpenAI's Electron app for Ubuntu/Debian with rebuilt native modules and APT repo

I built an unofficial Linux packaging pipeline for OpenAI Codex Desktop. It takes the upstream macOS Electron build, rebuilds native modules from source (`better-sqlite3`, `node-pty`), applies Linux patches, and ships as `.deb` and `.AppImage`.

**The interesting parts:**
- Fully automated CI pipeline: daily upstream ETag check → auto-download → rebuild → tag → release
- APT repository published to GitHub Pages with `dpkg-scanpackages`
- AppArmor profile to handle Ubuntu 24.04+ blocking unprivileged user namespaces
- Password store fallback (`kwallet`/`gnome-keyring` → `basic`) for headless environments
- Stale `SingletonLock` cleanup on startup
- Electron transparency patch (prevents black rectangles on software rendering)

**Tech stack:** Shell scripts, electron-builder, GitHub Actions, GitHub Pages

**Repo:** https://github.com/cuongducle/codex-linux

Happy to share details about the packaging approach if anyone's working on similar Electron-to-Linux projects!
