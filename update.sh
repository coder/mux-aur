#!/usr/bin/env bash
# Bump the mux AUR package to a new upstream release.
#
# Usage: ./update.sh <version>
#
# This script:
#   1. Updates `pkgver` in PKGBUILD to the provided version.
#   2. Resets `pkgrel` to 1.
#   3. Refreshes `sha256sums` via `updpkgsums` (from pacman-contrib).
#   4. Regenerates `.SRCINFO` via `makepkg --printsrcinfo`.
#   5. Creates a git commit with the changes.
#
# After running, push the branch (`git push origin main`) to trigger the
# GitHub Actions workflow that publishes the package to AUR.
#
# Requires Arch Linux tooling (`makepkg`, `updpkgsums`). On non-Arch hosts,
# run this inside the Docker image defined by the repo's Dockerfile, for
# example:
#
#   docker build -t mux-aur-build .
#   docker run --rm -it -v "$PWD:/work" -w /work mux-aur-build \
#     bash -lc 'sudo chown -R builder /work && ./update.sh <version>'

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

err() {
  printf 'error: %s\n' "$*" >&2
}

require_arch_tooling() {
  if ! command -v makepkg >/dev/null 2>&1; then
    err "\`makepkg\` not found. Run this on Arch Linux or inside the"
    err "        Docker image defined by ./Dockerfile (see header)."
    exit 1
  fi

  if ! command -v updpkgsums >/dev/null 2>&1; then
    echo "\`updpkgsums\` not found (needed to refresh sha256sums)."
    if command -v sudo >/dev/null 2>&1 && command -v pacman >/dev/null 2>&1; then
      echo "Installing pacman-contrib..."
      sudo pacman -S --noconfirm --needed pacman-contrib
    else
      err "install the \`pacman-contrib\` package first."
      exit 1
    fi
  fi
}

main() {
  local new_version="${1:-}"
  if [[ -z "${new_version}" ]]; then
    err "missing version argument"
    echo "usage: $0 <version>" >&2
    exit 1
  fi

  require_arch_tooling

  local current_version
  current_version="$(awk -F= '/^pkgver=/ { print $2; exit }' PKGBUILD)"
  if [[ -z "${current_version}" ]]; then
    err "failed to read current pkgver from PKGBUILD"
    exit 1
  fi

  echo "Current version: ${current_version}"
  echo "Target version:  ${new_version}"

  if [[ "${current_version}" != "${new_version}" ]]; then
    sed -i "s/^pkgver=.*/pkgver=${new_version}/" PKGBUILD
    sed -i "s/^pkgrel=.*/pkgrel=1/" PKGBUILD
  else
    echo "pkgver already at ${new_version}; refreshing sums and .SRCINFO only."
  fi

  updpkgsums
  makepkg --printsrcinfo > .SRCINFO

  git add PKGBUILD .SRCINFO
  if git diff --cached --quiet; then
    echo "No changes detected (PKGBUILD and .SRCINFO already up to date)."
    exit 0
  fi
  git commit -m "mux: update to ${new_version}"

  cat <<'EOF'

Next step: push main to origin to trigger the AUR publish workflow:

  git push origin main
EOF
}

main "$@"
