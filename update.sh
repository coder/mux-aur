#!/usr/bin/env bash
# Bump the mux AUR package to a new upstream release.
#
# Usage: ./update.sh <version>
#
# What it does:
#   1. Updates `pkgver` in PKGBUILD to the provided version.
#   2. Resets `pkgrel` to 1.
#   3. Refreshes `sha256sums` via `updpkgsums` (from pacman-contrib).
#   4. Regenerates `.SRCINFO` via `makepkg --printsrcinfo`.
#   5. Creates a git commit with the changes.
#
# Steps 1–4 always run inside the Arch container defined by ./Dockerfile
# (via docker or podman), regardless of the host OS — including on Arch
# Linux. This keeps behavior identical everywhere and avoids needing any
# Arch tooling on the host.
#
# The `git commit` always runs on the host so your git identity, signing
# key, and pre-commit hooks apply.
#
# Host requirements: git, and one of docker or podman.
#
# After running, push the branch (`git push origin main`) to trigger the
# GitHub Actions workflow that publishes the package to AUR.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

readonly CONTAINER_IMAGE="mux-aur-build"

err() {
  printf 'error: %s\n' "$*" >&2
}

# -----------------------------------------------------------------------------
# Container invocation (always used on the host).
# -----------------------------------------------------------------------------

pick_container_cli() {
  if command -v docker >/dev/null 2>&1; then
    printf docker
  elif command -v podman >/dev/null 2>&1; then
    printf podman
  else
    return 1
  fi
}

run_in_container() {
  local new_version="$1"
  local cli
  if ! cli="$(pick_container_cli)"; then
    err "neither \`docker\` nor \`podman\` is available."
    err "        Install Docker or Podman and try again."
    exit 1
  fi

  echo "==> building Arch container via ${cli}"
  "${cli}" build -t "${CONTAINER_IMAGE}" "${ROOT_DIR}" >&2

  local host_uid host_gid
  host_uid="$(id -u)"
  host_gid="$(id -g)"

  echo "==> running update inside ${cli} container"
  # Take ownership of /work so the unprivileged builder user can write
  # to PKGBUILD/.SRCINFO, re-exec this script (which hits update_files
  # because of the sentinel env var), and always restore host ownership
  # on exit via the EXIT trap — even if the inner run fails.
  "${cli}" run --rm \
    -v "${ROOT_DIR}:/work" \
    -w /work \
    -e "MUX_AUR_IN_CONTAINER=1" \
    "${CONTAINER_IMAGE}" \
    bash -lc "
      set -euo pipefail
      trap 'sudo chown -R ${host_uid}:${host_gid} /work' EXIT
      sudo chown -R builder:builder /work
      ./update.sh '${new_version}'
    "
}

# -----------------------------------------------------------------------------
# File mutations (runs inside the container).
# -----------------------------------------------------------------------------

update_files() {
  local new_version="$1"

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
}

# -----------------------------------------------------------------------------
# Host-only: git commit.
# -----------------------------------------------------------------------------

commit_changes() {
  local new_version="$1"
  git add PKGBUILD .SRCINFO
  if git diff --cached --quiet; then
    echo "No changes detected (PKGBUILD and .SRCINFO already up to date)."
    return 0
  fi
  git commit -m "mux: update to ${new_version}"
  cat <<'EOF'

Next step: push main to origin to trigger the AUR publish workflow:

  git push origin main
EOF
}

# -----------------------------------------------------------------------------
# Entry point.
# -----------------------------------------------------------------------------

main() {
  local new_version="${1:-}"
  if [[ -z "${new_version}" ]]; then
    err "missing version argument"
    echo "usage: $0 <version>" >&2
    exit 1
  fi

  if [[ -n "${MUX_AUR_IN_CONTAINER:-}" ]]; then
    # Inside the container: mutate files; let the host do the commit.
    update_files "${new_version}"
    return
  fi

  # On the host: always delegate file mutations to the container, then
  # commit locally so the user's git identity/hooks apply.
  run_in_container "${new_version}"
  commit_changes "${new_version}"
}

main "$@"
