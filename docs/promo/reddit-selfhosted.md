# Title: Codex Desktop on Linux — native packaging with APT repo, auto-updates, and Wayland support

Quick share for anyone running AI coding tools on Linux — I packaged OpenAI's Codex Desktop into native `.deb` and `.AppImage` builds with auto-updates.

**One-line install (Ubuntu/Debian):**
```bash
curl -fsSL https://cuongducle.github.io/codex-linux/install.sh | sudo bash
```

Includes:
- APT repo with auto-updates (`apt upgrade`)
- Wayland support with auto-detection
- AppArmor sandbox profile (Ubuntu 24.04+)
- `codex-desktop --doctor` diagnostics
- amd64 + arm64 support

**Repo:** https://github.com/cuongducle/codex-linux
