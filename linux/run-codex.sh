#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT_DIR}/app_asar"

if [[ ! -d "${APP_DIR}" ]]; then
  echo "Missing ${APP_DIR}. Run linux/scripts/extract-dmg.sh first." >&2
  exit 1
fi

if [[ -z "${CODEX_CLI_PATH:-}" ]]; then
  if command -v codex >/dev/null 2>&1; then
    CODEX_CLI_PATH="$(command -v codex)"
  else
    echo "CODEX_CLI_PATH is not set and codex is not on PATH." >&2
    exit 1
  fi
fi

ELECTRON_BIN="${ELECTRON_BIN:-}"
if [[ -z "${ELECTRON_BIN}" ]]; then
  if command -v electron >/dev/null 2>&1; then
    ELECTRON_BIN="$(command -v electron)"
  elif [[ -x "${ROOT_DIR}/node_modules/.bin/electron" ]]; then
    ELECTRON_BIN="${ROOT_DIR}/node_modules/.bin/electron"
  else
    echo "electron not found. Set ELECTRON_BIN or install local electron." >&2
    exit 1
  fi
fi

export ELECTRON_FORCE_IS_PACKAGED=1
export NODE_ENV=production
export CODEX_CLI_PATH

EXTRA_ELECTRON_ARGS=()
CHROME_SANDBOX_BIN="${ROOT_DIR}/node_modules/electron/dist/chrome-sandbox"
if [[ "${CODEX_DISABLE_SANDBOX:-0}" == "1" ]]; then
  EXTRA_ELECTRON_ARGS+=(--no-sandbox --disable-gpu-sandbox)
elif [[ -f "${CHROME_SANDBOX_BIN}" ]]; then
  sandbox_uid="$(stat -c '%u' "${CHROME_SANDBOX_BIN}" 2>/dev/null || echo '')"
  sandbox_mode="$(stat -c '%a' "${CHROME_SANDBOX_BIN}" 2>/dev/null || echo '')"
  if [[ "${sandbox_uid}" != "0" || "${sandbox_mode}" != "4755" ]]; then
    EXTRA_ELECTRON_ARGS+=(--no-sandbox --disable-gpu-sandbox)
  fi
fi

# Avoid Wayland+Vulkan renderer crash loops seen on some Linux setups.
if [[ "${CODEX_USE_X11:-1}" == "1" ]]; then
  EXTRA_ELECTRON_ARGS+=(--ozone-platform=x11)
fi
if [[ "${CODEX_DISABLE_VULKAN:-1}" == "1" ]]; then
  EXTRA_ELECTRON_ARGS+=(--disable-features=Vulkan)
fi
EXTRA_ELECTRON_ARGS+=(--use-gl="${CODEX_GL_BACKEND:-egl}")

exec "${ELECTRON_BIN}" "${EXTRA_ELECTRON_ARGS[@]}" "${APP_DIR}" "$@"
