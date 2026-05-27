const fs = require('fs');
const path = require('path');

module.exports = async function afterPack(context) {
  if (context.electronPlatformName !== 'linux') {
    return;
  }

  const appOutDir = context.appOutDir;
  const executableName = context.packager.platformSpecificBuildOptions.executableName || 'codex-desktop';
  const executablePath = path.join(appOutDir, executableName);
  const binaryPath = `${executablePath}.bin`;

  if (!fs.existsSync(executablePath)) {
    throw new Error(`Expected Electron executable not found: ${executablePath}`);
  }

  if (!fs.existsSync(binaryPath)) {
    fs.renameSync(executablePath, binaryPath);
  }

  const wrapper = String.raw`#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$(readlink -f "\${BASH_SOURCE[0]}")")" && pwd)"
ELECTRON_BIN="\${APP_DIR}/__EXECUTABLE_NAME__.bin"

find_codex_cli() {
  if [[ -n "\${CODEX_CLI_PATH:-}" && -x "\${CODEX_CLI_PATH}" ]]; then
    echo "\${CODEX_CLI_PATH}"
    return 0
  fi

  if command -v codex >/dev/null 2>&1; then
    command -v codex
    return 0
  fi

  local candidates=(
    "\${HOME}/.local/bin/codex"
    "\${HOME}/.cargo/bin/codex"
    "/usr/local/bin/codex"
    "/usr/bin/codex"
    "/opt/homebrew/bin/codex"
  )

  local node_bin
  for node_bin in "\${HOME}"/.nvm/versions/node/*/bin/codex; do
    [[ -x "\${node_bin}" ]] && candidates+=("\${node_bin}")
  done

  candidates+=(
    "\${APP_DIR}/resources/codex"
    "\${APP_DIR}/resources/bin/codex"
  )

  local candidate
  for candidate in "\${candidates[@]}"; do
    if [[ -x "\${candidate}" ]]; then
      echo "\${candidate}"
      return 0
    fi
  done

  return 1
}

if ! CODEX_CLI_PATH="$(find_codex_cli)"; then
  cat >&2 <<'ERR'
Codex Desktop could not find the Codex CLI.

Install the CLI first, or launch with CODEX_CLI_PATH=/path/to/codex.
Examples:
  npm install -g @openai/codex
  CODEX_CLI_PATH="$(command -v codex)" codex-desktop
ERR
  exit 127
fi

export CODEX_CLI_PATH
export NODE_ENV="\${NODE_ENV:-production}"
export ELECTRON_FORCE_IS_PACKAGED="\${ELECTRON_FORCE_IS_PACKAGED:-1}"

extra_args=()

if [[ "\${CODEX_DISABLE_SANDBOX:-0}" == "1" ]]; then
  extra_args+=(--no-sandbox --disable-gpu-sandbox)
fi

if [[ "\${CODEX_USE_X11:-1}" == "1" ]]; then
  extra_args+=(--ozone-platform=x11)
fi

if [[ "\${CODEX_DISABLE_VULKAN:-1}" == "1" ]]; then
  extra_args+=(--disable-features=Vulkan)
fi

if [[ -n "\${CODEX_GL_BACKEND:-egl}" ]]; then
  extra_args+=(--use-gl="\${CODEX_GL_BACKEND:-egl}")
fi

exec "\${ELECTRON_BIN}" "\${extra_args[@]}" "$@"
`.replace(/__EXECUTABLE_NAME__/g, executableName);

  fs.writeFileSync(executablePath, wrapper, { mode: 0o755 });
  fs.chmodSync(binaryPath, 0o755);

  const desktopFiles = fs.readdirSync(appOutDir).filter((file) => file.endsWith('.desktop'));
  for (const desktopFilename of desktopFiles) {
    const desktopFile = path.join(appOutDir, desktopFilename);
    const desktop = fs.readFileSync(desktopFile, 'utf8')
      .replace(/^Exec=.*$/gm, `Exec=${executableName} %U`);
    fs.writeFileSync(desktopFile, desktop);
  }
};
