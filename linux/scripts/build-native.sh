#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="${ROOT_DIR}/app_asar"
BUILD_DIR="${ROOT_DIR}/build_native"

if [[ ! -d "${APP_DIR}" ]]; then
  echo "Missing ${APP_DIR}. Run linux/scripts/extract-dmg.sh first." >&2
  exit 1
fi

if [[ ! -d "${ROOT_DIR}/node_modules" ]]; then
  echo "Missing local node_modules. Run: npm install" >&2
  exit 1
fi

ELECTRON_VERSION="${ELECTRON_VERSION:-}"
if [[ -z "${ELECTRON_VERSION}" ]]; then
  ELECTRON_VERSION="$(node -p "require('${APP_DIR}/package.json').devDependencies.electron || require('${ROOT_DIR}/node_modules/electron/package.json').version")"
fi

BETTER_SQLITE3_VERSION="$(node -p "require('${APP_DIR}/node_modules/better-sqlite3/package.json').version")"
NODE_PTY_VERSION="$(node -p "require('${APP_DIR}/node_modules/node-pty/package.json').version")"

mkdir -p "${BUILD_DIR}"
if [[ ! -f "${BUILD_DIR}/package.json" ]]; then
  (
    cd "${BUILD_DIR}"
    npm init -y >/dev/null
  )
fi

echo "Installing native build dependencies into ${BUILD_DIR}..."
(
  cd "${BUILD_DIR}"
  npm install \
    "electron@${ELECTRON_VERSION}" \
    "better-sqlite3@${BETTER_SQLITE3_VERSION}" \
    "node-pty@${NODE_PTY_VERSION}" \
    "@electron/rebuild"
)

echo "Rebuilding better-sqlite3 and node-pty for Electron ${ELECTRON_VERSION}..."
(
  cd "${BUILD_DIR}"
  npx electron-rebuild -v "${ELECTRON_VERSION}" -f --build-from-source -w better-sqlite3,node-pty
)

echo "Copying rebuilt native binaries into app_asar..."
mkdir -p "${APP_DIR}/node_modules/better-sqlite3/build/Release"
cp -f "${BUILD_DIR}/node_modules/better-sqlite3/build/Release/better_sqlite3.node" \
  "${APP_DIR}/node_modules/better-sqlite3/build/Release/better_sqlite3.node"
cp -f "${BUILD_DIR}/node_modules/node-pty/build/Release/pty.node" \
  "${APP_DIR}/node_modules/node-pty/build/Release/pty.node"

echo "Done rebuilding native modules."
