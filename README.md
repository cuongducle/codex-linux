# Codex Desktop Linux Wrapper

Run the macOS Codex Desktop bundle on Linux by extracting `app.asar`, rebuilding native modules, and launching with Electron.

## What This Repo Contains

- `linux/scripts/extract-dmg.sh`: Extract `Codex.dmg` and unpack `app.asar` to `app_asar/`.
- `linux/scripts/build-native.sh`: Rebuild Linux native modules (`better-sqlite3`, `node-pty`) for matching Electron ABI.
- `linux/run-codex.sh`: Launch app in packaged mode on Linux.
- `linux/codex.desktop`: Desktop launcher template.

## Requirements

- Linux x86_64
- `node` + `npm`
- `codex` CLI available on PATH
- Network access for npm/electron headers

## Quick Start

```bash
npm install
bash linux/scripts/extract-dmg.sh /path/to/Codex.dmg
bash linux/scripts/build-native.sh
CODEX_CLI_PATH="$(command -v codex)" bash linux/run-codex.sh
```

## Stable Linux Defaults

`linux/run-codex.sh` now defaults to:

- `--ozone-platform=x11`
- `--disable-features=Vulkan`
- `--use-gl=egl`

These defaults were added to avoid renderer flicker/crash loops on some Wayland setups.

Override when needed:

```bash
CODEX_USE_X11=0 CODEX_DISABLE_VULKAN=0 CODEX_GL_BACKEND=desktop bash linux/run-codex.sh
```

## Desktop Launcher

1. Copy this repo to your machine, for example: `~/codex-desktop-linux`
2. Copy desktop file:

```bash
install -Dm644 linux/codex.desktop ~/.local/share/applications/codex.desktop
update-desktop-database ~/.local/share/applications
```

3. (Optional) Put icon at `~/.local/share/icons/hicolor/512x512/apps/codex.png`  
4. If your launcher looks blurry/ugly, set `Icon=` in `~/.local/share/applications/codex.desktop` to an absolute PNG path.

## Notes

- `run-codex.sh` auto-falls back to `--no-sandbox` if Electron sandbox is not configured.
- Re-run `build-native.sh` after Codex/Electron version changes.
- This project ships scripts only; it does not redistribute Codex binaries.
