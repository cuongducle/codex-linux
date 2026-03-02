#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT_DIR}/app_asar"
TARGET="${1:-all}"
DMG_PATH="${2:-}"

print_usage() {
  cat <<EOF
Usage:
  bash scripts/build-packages.sh [deb|appimage|all] [/path/to/Codex.dmg]

Examples:
  bash scripts/build-packages.sh deb
  bash scripts/build-packages.sh appimage ./Codex.dmg
  bash scripts/build-packages.sh all

Notes:
  - If app_asar is missing and a DMG path is provided, setup is run automatically.
  - Output artifacts are written to: ${ROOT_DIR}/dist
EOF
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

if [[ "${TARGET}" == "-h" || "${TARGET}" == "--help" ]]; then
  print_usage
  exit 0
fi

case "${TARGET}" in
  deb) TARGET_ARGS=(--linux deb) ;;
  appimage) TARGET_ARGS=(--linux AppImage) ;;
  all) TARGET_ARGS=(--linux deb AppImage) ;;
  *)
    echo "Invalid target: ${TARGET}" >&2
    print_usage >&2
    exit 1
    ;;
esac

need_cmd node
need_cmd npm

if [[ ! -d "${APP_DIR}" || ! -f "${APP_DIR}/package.json" ]]; then
  if [[ -n "${DMG_PATH}" ]]; then
    echo "app_asar not found. Running setup using: ${DMG_PATH}"
    SKIP_APP_INSTALL=1 bash "${ROOT_DIR}/scripts/setup.sh" "${DMG_PATH}"
  else
    echo "Missing ${APP_DIR}. Run setup first, or pass a DMG path as arg #2." >&2
    exit 1
  fi
fi

if [[ ! -d "${ROOT_DIR}/node_modules" ]]; then
  echo "Installing root dependencies..."
  (
    cd "${ROOT_DIR}"
    npm install
  )
fi

echo "Building target: ${TARGET}"
(
  cd "${ROOT_DIR}"
  export CSC_IDENTITY_AUTO_DISCOVERY=false
  npx electron-builder --config electron-builder.yml "${TARGET_ARGS[@]}"
)

echo "Done. Artifacts:"
ls -1 "${ROOT_DIR}/dist"
