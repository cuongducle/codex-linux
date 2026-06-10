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

  const wrapper = `#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd "$(dirname "$(readlink -f "\${BASH_SOURCE[0]}")")" && pwd)"
ELECTRON_BIN="\${APP_DIR}/__EXECUTABLE_NAME__.bin"

# --- Config home resolution ---
XDG_CONFIG_HOME="\${XDG_CONFIG_HOME:-\${HOME}/.config}"

# --- SingletonLock stale cleanup ---
cleanup_singleton_lock() {
  local config_home="\${XDG_CONFIG_HOME}"
  local lock_found=""
  for candidate in "\${config_home}/Codex/SingletonLock" "\${config_home}/Codex Desktop/SingletonLock"; do
    if [[ -L "\${candidate}" ]]; then
      lock_found="\${candidate}"
      break
    fi
  done
  if [[ -n "\${lock_found}" ]]; then
    local target
    target="$(readlink "\${lock_found}")" || return 0
    local pid
    pid="\${target##*-}"
    if [[ "\${pid}" =~ ^[0-9]+$ ]]; then
      if ! kill -0 "\${pid}" 2>/dev/null; then
        rm -f "\${lock_found}"
      fi
    fi
  fi
}

# --- Doctor diagnostic ---
run_doctor() {
  echo "=== Codex Desktop Doctor Report ==="
  echo ""

  # Display server
  echo "--- Display Server ---"
  if [[ -n "\${WAYLAND_DISPLAY:-}" ]]; then
    echo "  Wayland detected: WAYLAND_DISPLAY=\${WAYLAND_DISPLAY}"
  else
    echo "  Wayland: not detected (WAYLAND_DISPLAY unset)"
  fi
  if [[ -n "\${XDG_SESSION_TYPE:-}" ]]; then
    echo "  XDG_SESSION_TYPE=\${XDG_SESSION_TYPE}"
  else
    echo "  XDG_SESSION_TYPE: unset"
  fi
  echo "  CODEX_USE_X11=\${CODEX_USE_X11:-unset}"
  echo "  CODEX_USE_WAYLAND=\${CODEX_USE_WAYLAND:-unset}"
  echo ""

  # GPU info
  echo "--- GPU ---"
  echo "  CODEX_DISABLE_GPU=\${CODEX_DISABLE_GPU:-unset}"
  echo "  CODEX_GL_BACKEND=\${CODEX_GL_BACKEND:-unset}"
  echo ""

  # Sandbox
  echo "--- Sandbox ---"
  local sandbox="\${APP_DIR}/chrome-sandbox"
  if [[ -e "\${sandbox}" ]]; then
    local sandbox_perms
    sandbox_perms="$(stat -c '%a' "\${sandbox}" 2>/dev/null || echo 'unknown')"
    echo "  chrome-sandbox path: \${sandbox}"
    echo "  chrome-sandbox permissions: \${sandbox_perms}"
    echo "  chrome-sandbox owner: $(stat -c '%U:%G' "\${sandbox}" 2>/dev/null || echo 'unknown')"
  else
    echo "  chrome-sandbox: not found at \${sandbox}"
  fi
  echo ""

  # CLI resolution
  echo "--- CLI ---"
  CODEX_CLI_PATH="" find_codex_cli >/dev/null 2>&1 && {
    echo "  Resolved CLI: $(find_codex_cli)"
  } || {
    echo "  CLI: NOT FOUND"
  }
  echo "  CODEX_CLI_PATH env: \${CODEX_CLI_PATH:-unset}"
  echo ""

  # Platform
  echo "--- Platform ---"
  echo "  OS: $(uname -s)"
  echo "  Arch: $(uname -m)"
  echo "  Kernel: $(uname -r)"
  echo ""

  # Electron
  echo "--- Electron ---"
  echo "  Binary: \${ELECTRON_BIN}"
  if [[ -x "\${ELECTRON_BIN}" ]]; then
    echo "  Status: executable"
  else
    echo "  Status: MISSING or not executable"
  fi
  echo ""
  echo "=== End of Report ==="
}

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

# --- Handle --doctor flag ---
for arg in "$@"; do
  if [[ "\${arg}" == "--doctor" ]]; then
    run_doctor
    exit 0
  fi
done

if ! CODEX_CLI_PATH="$(find_codex_cli)"; then
  cat >&2 <<'ERR'
Codex Desktop could not find the Codex CLI.

Install the CLI first, or launch with CODEX_CLI_PATH=/path/to/codex.
Examples:
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
  CODEX_CLI_PATH="$(command -v codex)" codex-desktop
ERR
  exit 127
fi

export CODEX_CLI_PATH
export NODE_ENV="\${NODE_ENV:-production}"
export ELECTRON_FORCE_IS_PACKAGED="\${ELECTRON_FORCE_IS_PACKAGED:-1}"

extra_args=()

# --- Sandbox ---
if [[ "\${CODEX_DISABLE_SANDBOX:-0}" == "1" ]]; then
  extra_args+=(--no-sandbox --disable-gpu-sandbox)
fi

# --- Display server / Wayland ---
if [[ "\${CODEX_USE_X11:-}" == "1" ]]; then
  extra_args+=(--ozone-platform=x11)
elif [[ "\${CODEX_USE_WAYLAND:-}" == "1" ]]; then
  extra_args+=(--ozone-platform=wayland --enable-features=WaylandWindowDecorations)
elif [[ -n "\${WAYLAND_DISPLAY:-}" ]]; then
  extra_args+=(--ozone-platform=wayland --enable-features=WaylandWindowDecorations)
else
  extra_args+=(--ozone-platform=x11)
fi
# --- Vulkan: only disable if explicitly requested ---
if [[ "\${CODEX_DISABLE_VULKAN:-}" == "1" ]]; then
  extra_args+=(--disable-features=Vulkan)
fi

# --- GL backend ---
if [[ -n "\${CODEX_GL_BACKEND:-egl}" ]]; then
  extra_args+=(--use-gl="\${CODEX_GL_BACKEND:-egl}")
fi

# --- Password store ---
if [[ -n "\${CODEX_PASSWORD_STORE:-}" ]]; then
  extra_args+=(--password-store="\${CODEX_PASSWORD_STORE}")
else
  extra_args+=(--password-store=basic)
fi

# --- Clean stale SingletonLock before launch ---
cleanup_singleton_lock

exec "\${ELECTRON_BIN}" "\${extra_args[@]}" "$@"
`.replace(/__EXECUTABLE_NAME__/g, executableName);

  fs.writeFileSync(executablePath, wrapper, { mode: 0o755 });
  fs.chmodSync(binaryPath, 0o755);

  const desktopFiles = fs.readdirSync(appOutDir).filter((file) => file.endsWith('.desktop'));
  for (const desktopFilename of desktopFiles) {
    const desktopFile = path.join(appOutDir, desktopFilename);
    let desktop = fs.readFileSync(desktopFile, 'utf8');

    // Rewrite Exec line to include %U for URI handling
    desktop = desktop.replace(/^Exec=.*$/gm, `Exec=${executableName} %U`);

    // Add StartupWMClass if not already present
    if (!desktop.includes('StartupWMClass')) {
      desktop = desktop.replace(/(\n\[Desktop Action[^\]]*\]|$)/, 'StartupWMClass=Codex\n$1');
    }

    // Add MimeType for deep-linking if not already present
    if (!desktop.includes('MimeType')) {
      desktop = desktop.replace(/(\n\[Desktop Action[^\]]*\]|$)/, 'MimeType=x-scheme-handler/codex:;\n$1');
    }

    // Fix Categories
    desktop = desktop.replace(/^Categories=.*$/gm, 'Categories=Development;Utility;');

    fs.writeFileSync(desktopFile, desktop);
  }

  // Hide the native menu bar and force opaque backgrounds on Linux.
  //
  // The upstream app is built for translucent macOS windows (vibrancy): its
  // html/body/sidebar surfaces are fully transparent (background: 0 0) and the
  // opaque background tokens are gated behind a Tailwind `browser:` variant that
  // never applies inside Electron. On Linux the window is forced opaque
  // (transparent:false below), so those transparent web regions sit on top of
  // the native window background. Under Wayland + EGL the two layers composite
  // out of sync, which makes the left sidebar flicker.
  //
  // Fix: paint html/body and the sidebar surface opaque using the app's OWN
  // theme tokens (var(--color-background-surface*)), so it stays correct in both
  // electron-dark and electron-light. A static stylesheet is enough — the CSS
  // variables react to theme changes on their own, so no MutationObserver /
  // polling is needed (the old re-application loop was itself a flicker source).
  const buildDir = path.join(appOutDir, 'resources', 'app', '.vite', 'build');
  const bootstrapPath = path.join(buildDir, 'bootstrap.js');
  if (fs.existsSync(bootstrapPath)) {
    let content = fs.readFileSync(bootstrapPath, 'utf8');
    const inject = `(()=>{const {app}=require("electron");app.on("browser-window-created",(e,w)=>{w.setMenuBarVisibility(false);w.autoHideMenuBar=true;w.webContents.on("dom-ready",()=>{w.webContents.executeJavaScript(\`(function(){var id="codex-linux-fix";if(document.getElementById(id))return;var s=document.createElement("style");s.id=id;s.textContent="html.electron-dark,html.electron-light{background-color:var(--color-background-surface-under)!important}body{background:var(--color-background-surface-under)!important}.app-shell-left-panel,aside,nav,[class*=sidebar],[class*=Sidebar]{background-color:var(--color-background-surface)!important;transition:none!important;backdrop-filter:none!important}";(document.head||document.documentElement).appendChild(s);})();\`).catch(()=>{});});});})();`;
    if (!content.includes('setMenuBarVisibility')) {
      // Inject autoUpdater no-op right after the menu bar injection
      const autoUpdaterNoop = `(()=>{const _r=require;const _req=_r.bind(module);const _m=new Proxy({},{get:(t,k)=>k==="autoUpdater"?{checkForUpdates:()=>Promise.resolve(),checkForUpdatesAndNotify:()=>Promise.resolve(),getAutoUpdateAndNotifyPromise:()=>Promise.resolve(),quitAndInstall:()=>{},on:()=>({}),once:()=>({}),removeAllListeners:()=>({})}:undefined});Object.defineProperty(module,"exports",{get:()=>_m,set:(v)=>{},configurable:true});})();`;
      content = content.replace('require("electron");', `require("electron");${inject}${autoUpdaterNoop}`);
      fs.writeFileSync(bootstrapPath, content);
    } else if (content.includes('const updateBg=()=>{try{')) {
      // Replace the previous injection with the new one
      content = content.replace(/\(\(\)=>\{const \{app,nativeTheme\}=require\("electron"\);app\.on\("browser-window-created",\(e,w\)=>\{w\.setMenuBarVisibility\(false\);w\.autoHideMenuBar=true;const updateBg=\(\)=>\{try\{.*?\}\)\(\);/g, inject);
      fs.writeFileSync(bootstrapPath, content);
    }
  }

  // Force disable BrowserWindow transparency to avoid black rectangles when using software rendering
  if (fs.existsSync(buildDir)) {
    const files = fs.readdirSync(buildDir);
    for (const file of files) {
      if (file.endsWith('.js')) {
        const filePath = path.join(buildDir, file);
        let content = fs.readFileSync(filePath, 'utf8');
        let modified = false;
        if (content.includes('transparent:!0')) {
          content = content.replace(/transparent:!0/g, 'transparent:!1');
          modified = true;
        }
        if (content.includes('transparent:true')) {
          content = content.replace(/transparent:true/g, 'transparent:false');
          modified = true;
        }
        if (modified) {
          fs.writeFileSync(filePath, content);
        }
      }
    }
  }

  // Normalize permissions: dirs 755, files 644, executables 755
};
