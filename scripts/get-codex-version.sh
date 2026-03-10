#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DMG_PATH="${1:-${ROOT_DIR}/Codex.dmg}"
WORK_DIR="${ROOT_DIR}/work_version_check"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

need_cmd node

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
  echo "No 7z binary found. Install 7zip or run npm install first." >&2
  exit 1
fi

rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}"

EXTRACT_LOG="${WORK_DIR}/7z-extract.log"
set +e
"${SEVEN_Z_BIN}" x -y -o"${WORK_DIR}" "${DMG_PATH}" >"${EXTRACT_LOG}" 2>&1
EXTRACT_RC=$?
set -e
if [[ "${EXTRACT_RC}" -ne 0 ]]; then
  if grep -q "Dangerous link path was ignored" "${EXTRACT_LOG}"; then
    echo "7z warning: ignored unsafe symlink entries in DMG, continuing." >&2
  else
    cat "${EXTRACT_LOG}" >&2
    exit "${EXTRACT_RC}"
  fi
fi

ASAR_PATH="$(find "${WORK_DIR}" -type f -path "*Codex.app/Contents/Resources/app.asar" | head -n 1 || true)"
if [[ -z "${ASAR_PATH}" ]]; then
  ASAR_PATH="$(find "${WORK_DIR}" -type f -name "app.asar" | head -n 1 || true)"
fi
if [[ -z "${ASAR_PATH}" ]]; then
  cat "${EXTRACT_LOG}" >&2 || true
  echo "Could not find app.asar in extracted DMG payload." >&2
  exit 1
fi

CODEX_VERSION="$(
  node - "${ASAR_PATH}" <<'NODE'
const fs = require("fs");
const asar = require("asar");

const asarPath = process.argv[2];
const pkgRaw = asar.extractFile(asarPath, "package.json");
const pkg = JSON.parse(Buffer.isBuffer(pkgRaw) ? pkgRaw.toString("utf8") : pkgRaw);

if (!pkg.version) {
  process.exit(2);
}
process.stdout.write(String(pkg.version));
NODE
)"

if [[ -z "${CODEX_VERSION}" ]]; then
  echo "Failed to read Codex version from app.asar/package.json" >&2
  exit 1
fi

echo "${CODEX_VERSION}"
