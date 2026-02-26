# Codex Desktop Linux

A clean Linux wrapper to run Codex Desktop with a minimal setup flow.

## Quick Start

```bash
# 1) Download Codex.dmg
curl -fL "https://persistent.oaistatic.com/codex-app-prod/Codex.dmg" -o Codex.dmg

# 2) Create Linux app from local DMG (run once)
bash scripts/setup.sh ./Codex.dmg

# 3) Open Codex Linux app
codex-desktop
# or open from app menu: Codex
```

## Requirements

- Linux x86_64
- `node` and `npm`
- `codex` CLI available on `PATH`

## What Setup Does

`scripts/setup.sh` handles everything needed (one-time):

- install dependencies
- extract `app.asar` from `Codex.dmg`
- rebuild native modules for Linux
- create Linux app command: `~/.local/bin/codex-desktop`
- create desktop app entry: `~/.local/share/applications/codex.desktop`

## Project Layout

```text
scripts/
  setup.sh                # one-time app creation command
  internal/               # internal pipeline scripts
```

## Notes

- Re-run setup after Codex Desktop/Electron changes.
- This repository ships scripts only, not Codex binaries.
- Official source for app setup and download flow: https://developers.openai.com/codex/quickstart?setup=app
