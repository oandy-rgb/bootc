#!/usr/bin/env bash
set -euo pipefail

LOCAL_REPO="/run/media/oandy/X9 Pro/bootc/restic-repo"
SOURCE="/var/home/oandy"
TAG="auto-$(date +%Y%m%d-%H%M)"

if [ -d "/run/media/oandy/X9 Pro" ]; then
  echo "備份至 X9 Pro..."
  restic \
    -r "$LOCAL_REPO" \
    backup "$SOURCE" \
    --tag "$TAG" \
    --one-file-system \
    --exclude=".cache" \
    --exclude="node_modules" \
    --exclude="target" \
    --exclude=".direnv" \
    --exclude=".var" \
    --exclude=".local/share/containers"
  echo "✅ X9 Pro 完成"
else
  echo "⚠️ X9 Pro 不在，跳過"
fi
