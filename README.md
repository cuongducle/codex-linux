# Codex Desktop for Linux

Unofficial Linux packaging for Codex Desktop.

## User Installation (Release Only)

End users only need files from **GitHub Releases**.
No need to clone this repo or install Node.js.

Release page: https://github.com/cuongducle/codex-linux/releases/latest

### Option 1: Debian / Ubuntu (`.deb`)

1. Go to [Releases](https://github.com/cuongducle/codex-linux/releases/latest).
2. Download the latest `codex-desktop-*.deb` file.
3. Install:

```bash
sudo apt install ./codex-desktop-*.deb
```

### Option 2: Any Distro (`.AppImage`)

1. Go to [Releases](https://github.com/cuongducle/codex-linux/releases/latest).
2. Download the latest `codex-desktop-*-x86_64.AppImage`.
3. Run:

```bash
chmod +x codex-desktop-*-x86_64.AppImage
./codex-desktop-*-x86_64.AppImage
```

### Updating

- `.deb`: download and install the newer release file.
- `.AppImage`: replace the old AppImage with the new release file.

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

### 2) Publish release

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

- Sends a `HEAD` request to upstream `Codex.dmg` and checks `ETag` first
- If `ETag` is unchanged: skip download
- If `ETag` changed: download `Codex.dmg`, extract Codex app version from `app.asar/package.json`
- Compares that version with latest git tag (`v*`)
- If newer: updates `upstream-version.txt`, updates `upstream-etag.txt`, commits, and creates a new tag `v<codex-version>`

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
- Auto-upload release artifacts (`.deb`, `.AppImage`) to GitHub Releases
- Optional APT repo publish on release tag

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
