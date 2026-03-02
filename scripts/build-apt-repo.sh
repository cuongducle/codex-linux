#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_DIR="${1:-${ROOT_DIR}/apt-public}"
PACKAGE_NAME="${PACKAGE_NAME:-codex-desktop}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

need_cmd dpkg-scanpackages
need_cmd gzip
need_cmd sha256sum
need_cmd md5sum
need_cmd stat

mkdir -p "${REPO_DIR}"
mkdir -p "${REPO_DIR}/pool/main/c/${PACKAGE_NAME}"
mkdir -p "${REPO_DIR}/dists/stable/main/binary-amd64"

shopt -s nullglob
deb_files=("${REPO_DIR}"/*.deb)
if [[ "${#deb_files[@]}" -eq 0 ]]; then
  echo "No .deb files found in ${REPO_DIR}" >&2
  exit 1
fi

for deb in "${deb_files[@]}"; do
  cp -f "${deb}" "${REPO_DIR}/pool/main/c/${PACKAGE_NAME}/"
done

PACKAGES_FILE="${REPO_DIR}/dists/stable/main/binary-amd64/Packages"
PACKAGES_GZ_FILE="${PACKAGES_FILE}.gz"
RELEASE_FILE="${REPO_DIR}/dists/stable/Release"

(
  cd "${REPO_DIR}"
  dpkg-scanpackages --multiversion pool /dev/null > "${PACKAGES_FILE#${REPO_DIR}/}"
)
gzip -9 -c "${PACKAGES_FILE}" > "${PACKAGES_GZ_FILE}"

packages_rel="main/binary-amd64/Packages"
packages_gz_rel="main/binary-amd64/Packages.gz"
packages_size="$(stat -c%s "${PACKAGES_FILE}")"
packages_gz_size="$(stat -c%s "${PACKAGES_GZ_FILE}")"
packages_md5="$(md5sum "${PACKAGES_FILE}" | awk '{print $1}')"
packages_gz_md5="$(md5sum "${PACKAGES_GZ_FILE}" | awk '{print $1}')"
packages_sha256="$(sha256sum "${PACKAGES_FILE}" | awk '{print $1}')"
packages_gz_sha256="$(sha256sum "${PACKAGES_GZ_FILE}" | awk '{print $1}')"

cat > "${RELEASE_FILE}" <<EOF
Origin: ${PACKAGE_NAME}
Label: ${PACKAGE_NAME}
Suite: stable
Codename: stable
Date: $(LC_ALL=C date -Ru)
Architectures: amd64
Components: main
Description: ${PACKAGE_NAME} APT repository
MD5Sum:
 ${packages_md5} ${packages_size} ${packages_rel}
 ${packages_gz_md5} ${packages_gz_size} ${packages_gz_rel}
SHA256:
 ${packages_sha256} ${packages_size} ${packages_rel}
 ${packages_gz_sha256} ${packages_gz_size} ${packages_gz_rel}
EOF

echo "APT repository generated at: ${REPO_DIR}"
echo "Package index: ${PACKAGES_FILE}"
echo "Release file: ${RELEASE_FILE}"
