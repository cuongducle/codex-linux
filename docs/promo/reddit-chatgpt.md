# Title: Running Codex Desktop natively on Linux — unofficial .deb/AppImage with Wayland support and auto-updates

If you're on Linux and want to use OpenAI's Codex Desktop (which only officially supports macOS), I packaged it into native Linux builds.

**Features:**
- `.deb` for Ubuntu/Debian + `.AppImage` for any distro
- Wayland auto-detection with native window decorations
- Auto-updates (CI monitors upstream daily and publishes new releases)
- APT repository for `apt upgrade` updates
- Sandbox handling with AppArmor profiles
- Built-in `--doctor` command for diagnostics
- Supports amd64 and arm64

**One-line install:**
```bash
curl -fsSL https://cuongducle.github.io/codex-linux/install.sh | sudo bash
```

**Repo:** https://github.com/cuongducle/codex-linux

Unofficial project — builds from the upstream macOS app, doesn't redistribute source code.
