#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root (sudo)." >&2
  exit 1
fi

SOURCE_FILE="/etc/apt/sources.list.d/codex-desktop.list"
REPO_LINE="deb [trusted=yes] https://cuongducle.github.io/codex-linux/ stable main"

echo "${REPO_LINE}" > "${SOURCE_FILE}"
apt update
apt install -y codex-desktop
echo "Installed: codex-desktop"
