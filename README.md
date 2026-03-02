# Codex Desktop for Linux

Unofficial Linux packaging workflow for Codex Desktop with support for **Debian APT** and **AppImage**.

## Public Installation

### Debian / Ubuntu (APT Repository)

After you publish a release tag, users can install with:

```bash
# One-command installer
curl -fsSL https://<owner>.github.io/<repo>/install.sh | sudo bash

# Or manual setup
echo "deb [trusted=yes] https://<owner>.github.io/<repo>/ stable main" | sudo tee /etc/apt/sources.list.d/codex-desktop.list
sudo apt update
sudo apt install codex-desktop
```

Updates:

```bash
sudo apt update
sudo apt upgrade
```

### AppImage (Any Distro)

Download from GitHub Releases:

```bash
wget https://github.com/<owner>/<repo>/releases/latest/download/codex-desktop-<version>-x86_64.AppImage
chmod +x codex-desktop-*-x86_64.AppImage
./codex-desktop-*-x86_64.AppImage
```

## Maintainer Flow (Build + Publish)

### 1) Build locally

```bash
# Download upstream DMG
curl -fL "https://persistent.oaistatic.com/codex-app-prod/Codex.dmg" -o Codex.dmg

# Extract payload + rebuild Linux native modules
bash scripts/setup.sh ./Codex.dmg

# Build packages
npm run build:linux
# or separately:
# npm run build:deb
# npm run build:appimage
```

Output artifacts are in `dist/`.

### 2) Publish public files

Push a version tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

GitHub Actions will automatically:

- Build `.deb` and `.AppImage`
- Upload both files to GitHub Releases
- Generate APT repository metadata (`Packages`, `Release`)
- Publish APT repo to `gh-pages`

## Daily Auto-Update

Workflow [`check-upstream.yml`](.github/workflows/check-upstream.yml) runs daily and:

- Downloads latest upstream `Codex.dmg`
- Extracts Codex app version from `app.asar/package.json`
- Compares with latest git tag (`v*`)
- If newer: updates `upstream-version.txt`, commits, and creates a new tag `v<codex-version>`

That new tag triggers the release workflow, which publishes new `.deb`, `.AppImage`, and refreshed APT metadata.

## Required Repository Settings

1. Enable GitHub Pages:
- Settings -> Pages -> Source: `Deploy from a branch`
- Branch: `gh-pages` (root)

2. Keep repository public (for public downloads).

3. Add repository secret `RELEASE_PAT` (recommended):
- Create a Personal Access Token with `repo` + `workflow` scopes.
- Save it in repo Settings -> Secrets and variables -> Actions -> `RELEASE_PAT`.
- This is used by daily update workflow to push tags that can trigger downstream release workflow.

## Features

- Packaging targets: **DEB** and **AppImage** only
- Linux native module rebuild (`better-sqlite3`, `node-pty`)
- Auto-publish APT repo on release tag
- Auto-upload AppImage to GitHub Releases

## Repository Structure

- `scripts/setup.sh` - Extract from DMG, rebuild native modules, local launcher setup
- `scripts/build-packages.sh` - Build DEB/AppImage via electron-builder
- `scripts/build-apt-repo.sh` - Generate Debian repository metadata
- `scripts/generate-apt-install-script.sh` - Generate public `install.sh`
- `.github/workflows/release.yml` - CI build + release + APT publish
- `electron-builder.yml` - Packaging config

## Notes

- This is an unofficial packaging project.
- This repository does not redistribute Codex source; it builds from upstream `Codex.dmg`.
- APT setup currently uses `trusted=yes` (unsigned repository).
