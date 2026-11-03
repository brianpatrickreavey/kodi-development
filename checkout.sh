#!/usr/bin/env bash
# Clone any live repo that is not already in this directory.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$root"

repos=(
  auth0-ciam-client
  kodi.script.module.auth0-ciam-client
  kodi.plugin.video.angelstudios
  kodi.plugin.video.crossfitwod
  kodi.plugin.video.wodi
  kodi-addon-builder
  repository.kodi.reavey05.com
)

for name in "${repos[@]}"; do
  if [ -d "$name/.git" ]; then
    echo "present: $name"
  else
    git clone "https://github.com/brianpatrickreavey/${name}.git" "$name"
  fi
done
