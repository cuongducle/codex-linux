#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK_DIR="${ROOT_DIR}/work_dmg"
APP_ASAR_DIR="${ROOT_DIR}/app_asar"
APP_RESOURCES_DIR="${ROOT_DIR}/app_resources"
DMG_PATH="${1:-${ROOT_DIR}/Codex.dmg}"
CODEX_CLI_SOURCE_PATH="${CODEX_CLI_SOURCE_PATH:-}"

if [[ ! -f "${DMG_PATH}" ]]; then
  echo "DMG not found: ${DMG_PATH}" >&2
  exit 1
fi

if [[ -x "${ROOT_DIR}/tools/7zz" ]]; then
  SEVEN_Z_BIN="${ROOT_DIR}/tools/7zz"
elif command -v 7zz >/dev/null 2>&1; then
  SEVEN_Z_BIN="$(command -v 7zz)"
elif command -v 7z >/dev/null 2>&1; then
  SEVEN_Z_BIN="$(command -v 7z)"
elif [[ -d "${ROOT_DIR}/node_modules" ]]; then
  SEVEN_Z_BIN="$(node -e "console.log(require('7zip-bin').path7za)")"
else
  echo "No 7z binary found. Install 7zip or place tools/7zz." >&2
  exit 1
fi

rm -rf "${WORK_DIR}" "${APP_ASAR_DIR}" "${APP_RESOURCES_DIR}"
mkdir -p "${WORK_DIR}" "${APP_ASAR_DIR}" "${APP_RESOURCES_DIR}/bin"

echo "[1/3] Extracting DMG..."
EXTRACT_LOG="${WORK_DIR}/7z-extract.log"
set +e
"${SEVEN_Z_BIN}" x -y -o"${WORK_DIR}" "${DMG_PATH}" >"${EXTRACT_LOG}" 2>&1
EXTRACT_RC=$?
set -e
if [[ "${EXTRACT_RC}" -ne 0 ]]; then
  if grep -q "Dangerous link path was ignored" "${EXTRACT_LOG}"; then
    echo "7z warning: ignored unsafe symlink entries in DMG, continuing."
  else
    cat "${EXTRACT_LOG}" >&2
    exit "${EXTRACT_RC}"
  fi
fi

echo "[2/3] Locating app.asar..."
ASAR_PATH="$(find "${WORK_DIR}" -type f -path "*/Contents/Resources/app.asar" | head -n 1 || true)"
if [[ -z "${ASAR_PATH}" ]]; then
  ASAR_PATH="$(find "${WORK_DIR}" -type f -name "app.asar" | head -n 1 || true)"
fi
if [[ -z "${ASAR_PATH}" ]]; then
  cat "${EXTRACT_LOG}" >&2 || true
  echo "Could not find app.asar after extraction." >&2
  exit 1
fi

BIN_DIR_PATH="$(find "${WORK_DIR}" -type d -path "*/Contents/Resources/bin" | head -n 1 || true)"
if [[ -n "${BIN_DIR_PATH}" ]]; then
  mkdir -p "${APP_RESOURCES_DIR}/bin"
  cp -a "${BIN_DIR_PATH}/." "${APP_RESOURCES_DIR}/bin/"
fi

# Upstream layout can change. If Resources/bin wasn't found, fallback to
# any executable named "codex" under the app Resources tree.
if [[ ! -f "${APP_RESOURCES_DIR}/bin/codex" ]]; then
  ALT_CODEX_PATH="$(find "${WORK_DIR}" -type f -path "*/Contents/Resources/*" -name codex | head -n 1 || true)"
  if [[ -n "${ALT_CODEX_PATH}" ]]; then
    cp -f "${ALT_CODEX_PATH}" "${APP_RESOURCES_DIR}/bin/codex"
    chmod +x "${APP_RESOURCES_DIR}/bin/codex" || true
  fi
fi

echo "[3/3] Extracting app.asar -> ${APP_ASAR_DIR}"
npx --yes asar extract "${ASAR_PATH}" "${APP_ASAR_DIR}"

if [[ ! -f "${APP_RESOURCES_DIR}/bin/codex" ]]; then
  echo "Could not locate bundled Codex CLI in DMG resources." >&2
  echo "Expected path similar to: */Contents/Resources/bin/codex" >&2
  exit 1
fi

# Optional Linux override for CI packaging. Useful because DMG bundles
# macOS binaries, while Linux packages require a Linux codex binary.
if [[ -n "${CODEX_CLI_SOURCE_PATH}" ]]; then
  if [[ ! -f "${CODEX_CLI_SOURCE_PATH}" ]]; then
    echo "CODEX_CLI_SOURCE_PATH does not exist: ${CODEX_CLI_SOURCE_PATH}" >&2
    exit 1
  fi
  cp -f "${CODEX_CLI_SOURCE_PATH}" "${APP_RESOURCES_DIR}/bin/codex"
  chmod +x "${APP_RESOURCES_DIR}/bin/codex" || true
fi

echo "Done."
echo "app_asar: ${APP_ASAR_DIR}"
if [[ -d "${APP_RESOURCES_DIR}/bin" ]]; then
  echo "app_resources/bin: ${APP_RESOURCES_DIR}/bin"
fi
