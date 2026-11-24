#!/usr/bin/env bash
# Build the Trivy Azure Pipelines extension (V2 task + UI) into a VSIX.
# Usage: ./build-vsix.sh [release-version]   (default: v2.7.4; include "dev" for the private variant)
# Set SKIP_INSTALL=1 to skip dependency installation.
set -euo pipefail

cd "$(dirname "$0")"

export RELEASE_VERSION="${1:-${RELEASE_VERSION:-v2.7.4}}"
TASK_JSON="trivy-task/trivyV2/task.json"

# Packaging bumps the patch version in task.json; restore it afterwards.
BACKUP="$(mktemp)"
cp "$TASK_JSON" "$BACKUP"
trap 'cp "$BACKUP" "$TASK_JSON"; rm -f "$BACKUP"' EXIT

if [ -z "${SKIP_INSTALL:-}" ]; then
  echo "==> Installing dependencies"
  (cd trivy-task/trivyV2 && yarn install)
  (cd ui && yarn install)
fi

echo "==> Building V2 task"
(cd trivy-task/trivyV2 && node ../../node_modules/typescript/bin/tsc -b tsconfig.json)

echo "==> Building UI"
(cd ui && yarn build)

echo "==> Packaging VSIX (RELEASE_VERSION=$RELEASE_VERSION)"
rm -f ./*.vsix
node node_modules/tfx-cli/_build/tfx-cli.js extension create --manifest-js vss-manifest.js

echo "==> Done:"
ls -la ./*.vsix
