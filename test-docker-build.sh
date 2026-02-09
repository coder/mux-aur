#!/usr/bin/env bash
set -euo pipefail

IMAGE_TAG="${IMAGE_TAG:-mux-aur-build}"
WORKDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "error: docker is not installed or not in PATH" >&2
  exit 1
fi

echo "==> Building Docker image: ${IMAGE_TAG}"
docker build -t "${IMAGE_TAG}" "${WORKDIR}"

echo "==> Running package build in container"
if [[ -t 0 && -t 1 ]]; then
  docker run --rm -it "${IMAGE_TAG}"
else
  docker run --rm "${IMAGE_TAG}"
fi

echo "==> Done."
