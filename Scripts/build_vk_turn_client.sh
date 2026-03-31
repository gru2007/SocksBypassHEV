#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/TurnProxyExtension/Tools/vk-turn-client"
TMP="$ROOT/ThirdParty/vk-turn-proxy"

if ! command -v go >/dev/null 2>&1; then
  echo "go is required"
  exit 1
fi

if [ ! -d "$TMP/.git" ]; then
  git clone --depth 1 https://github.com/cacggghp/vk-turn-proxy.git "$TMP"
else
  git -C "$TMP" pull --ff-only
fi

pushd "$TMP" >/dev/null
GOOS=ios GOARCH=arm64 CGO_ENABLED=1 go build -o "$OUT" ./client
popd >/dev/null

chmod +x "$OUT"
echo "Built $OUT"
