#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DMG_PATH="${1:-${ROOT_DIR}/Codex.dmg}"
SKIP_APP_INSTALL="${SKIP_APP_INSTALL:-0}"

print_usage() {
  cat <<EOF
Usage:
  bash scripts/setup.sh /path/to/Codex.dmg
  bash scripts/setup.sh

Notes:
  - If no path is provided, script uses: ${ROOT_DIR}/Codex.dmg
  - Set SKIP_APP_INSTALL=1 to skip Linux app integration
EOF
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    return 1
  fi
}

echo "== Codex Desktop Linux setup =="

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  print_usage
  exit 0
fi

need_cmd node
need_cmd npm

if [[ ! -f "${DMG_PATH}" ]]; then
  echo "DMG not found: ${DMG_PATH}" >&2
  print_usage >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "The 'codex' CLI is not found on PATH." >&2
  echo "Install Codex CLI first, then rerun this script." >&2
  exit 1
fi

echo "[1/5] Installing npm dependencies..."
(
  cd "${ROOT_DIR}"
  npm install
)

echo "[2/5] Extracting app payload from DMG..."
bash "${ROOT_DIR}/scripts/internal/extract-dmg.sh" "${DMG_PATH}"

echo "[3/5] Rebuilding native modules..."
bash "${ROOT_DIR}/scripts/internal/build-native.sh"

echo "[4/6] Running smoke check..."
if command -v electron >/dev/null 2>&1; then
  electron --version >/dev/null || true
elif [[ -x "${ROOT_DIR}/node_modules/.bin/electron" ]]; then
  "${ROOT_DIR}/node_modules/.bin/electron" --version >/dev/null || true
fi

if [[ "${SKIP_APP_INSTALL}" == "1" ]]; then
  echo "[5/6] Skipped Linux app integration (SKIP_APP_INSTALL=1)."
else
  echo "[5/6] Installing Linux app command..."
  mkdir -p "${HOME}/.local/bin"
  cat > "${HOME}/.local/bin/codex-desktop" <<EOF
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="${ROOT_DIR}"
APP_DIR="\${ROOT_DIR}/app_asar"
if [[ ! -d "\${APP_DIR}" ]]; then
  echo "Missing \${APP_DIR}. Re-run: bash \${ROOT_DIR}/scripts/setup.sh /path/to/Codex.dmg" >&2
  exit 1
fi
if [[ -z "\${CODEX_CLI_PATH:-}" ]]; then
  if command -v codex >/dev/null 2>&1; then
    CODEX_CLI_PATH="\$(command -v codex)"
  else
    echo "CODEX_CLI_PATH is not set and codex is not on PATH." >&2
    exit 1
  fi
fi
ELECTRON_BIN="\${ELECTRON_BIN:-}"
if [[ -z "\${ELECTRON_BIN}" ]]; then
  if command -v electron >/dev/null 2>&1; then
    ELECTRON_BIN="\$(command -v electron)"
  elif [[ -x "\${ROOT_DIR}/node_modules/.bin/electron" ]]; then
    ELECTRON_BIN="\${ROOT_DIR}/node_modules/.bin/electron"
  else
    echo "electron not found. Install electron or keep local node_modules." >&2
    exit 1
  fi
fi
export ELECTRON_FORCE_IS_PACKAGED=1
export NODE_ENV=production
export CODEX_CLI_PATH
EXTRA_ELECTRON_ARGS=()
CHROME_SANDBOX_BIN="\${ROOT_DIR}/node_modules/electron/dist/chrome-sandbox"
if [[ "\${CODEX_DISABLE_SANDBOX:-0}" == "1" ]]; then
  EXTRA_ELECTRON_ARGS+=(--no-sandbox --disable-gpu-sandbox)
elif [[ -f "\${CHROME_SANDBOX_BIN}" ]]; then
  sandbox_uid="\$(stat -c '%u' "\${CHROME_SANDBOX_BIN}" 2>/dev/null || echo '')"
  sandbox_mode="\$(stat -c '%a' "\${CHROME_SANDBOX_BIN}" 2>/dev/null || echo '')"
  if [[ "\${sandbox_uid}" != "0" || "\${sandbox_mode}" != "4755" ]]; then
    EXTRA_ELECTRON_ARGS+=(--no-sandbox --disable-gpu-sandbox)
  fi
fi
if [[ "\${CODEX_USE_X11:-1}" == "1" ]]; then
  EXTRA_ELECTRON_ARGS+=(--ozone-platform=x11)
fi
if [[ "\${CODEX_DISABLE_VULKAN:-1}" == "1" ]]; then
  EXTRA_ELECTRON_ARGS+=(--disable-features=Vulkan)
fi
EXTRA_ELECTRON_ARGS+=(--use-gl="\${CODEX_GL_BACKEND:-egl}")
exec "\${ELECTRON_BIN}" "\${EXTRA_ELECTRON_ARGS[@]}" "\${APP_DIR}" "\$@"
EOF
  chmod +x "${HOME}/.local/bin/codex-desktop"

  echo "[6/6] Installing Linux desktop application..."
  mkdir -p "${HOME}/.local/share/applications"
  cat > "${HOME}/.local/share/applications/codex.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Codex
Comment=Codex Desktop (Linux app)
Exec=${HOME}/.local/bin/codex-desktop
Terminal=false
Icon=codex
Categories=Development;
StartupNotify=true
EOF

  if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${HOME}/.local/share/applications" || true
  fi
fi

echo
echo "Linux app setup complete."
echo "Run now: ${HOME}/.local/bin/codex-desktop"
echo "Or launch from app menu: Codex"
