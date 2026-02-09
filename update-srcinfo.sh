#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

if command -v makepkg >/dev/null 2>&1; then
  CONFIG_PATH="/etc/makepkg.conf"
  if [[ ! -f "${CONFIG_PATH}" ]]; then
    CONFIG_PATH="$(dirname "$(command -v makepkg)")/../etc/makepkg.conf"
  fi

  if [[ ! -f "${CONFIG_PATH}" ]]; then
    echo "error: makepkg.conf not found for local makepkg" >&2
    exit 1
  fi

  makepkg --config "${CONFIG_PATH}" --printsrcinfo > .SRCINFO
  echo "Updated ${ROOT_DIR}/.SRCINFO"
  exit 0
fi

if ! command -v nix >/dev/null 2>&1; then
  echo "error: neither makepkg nor nix found in PATH" >&2
  exit 1
fi

nix shell nixpkgs#pacman -c bash -lc '
set -euo pipefail
CONF="/etc/makepkg.conf"
if [[ ! -f "${CONF}" ]]; then
  CONF="$(dirname "$(command -v makepkg)")/../etc/makepkg.conf"
fi
if [[ ! -f "${CONF}" ]]; then
  echo "error: makepkg.conf not found in nix shell" >&2
  exit 1
fi
makepkg --config "${CONF}" --printsrcinfo
' > .SRCINFO

echo "Updated ${ROOT_DIR}/.SRCINFO (via nix shell)"
