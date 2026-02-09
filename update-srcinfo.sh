#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

if ! command -v makepkg >/dev/null 2>&1; then
  echo "error: makepkg not found in PATH" >&2
  exit 1
fi

makepkg --printsrcinfo > .SRCINFO
echo "Updated ${ROOT_DIR}/.SRCINFO"
