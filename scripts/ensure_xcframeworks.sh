#!/usr/bin/env bash
# 对外 Demo 自带 XCFrameworks/；缺失时从 SDK 工程构建并 sync
set -euo pipefail
DEMO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${DEMO}/XCFrameworks"
NEED=(TDAdsBase TDAdsSDK TDAdsJDSDK TDAdsAdGain TDAdsLtmb)  # TDAdsDusk / TDAdsTimeout 不进对外 Demo
missing=0
for m in "${NEED[@]}"; do
  if [[ ! -d "${DEST}/${m}.xcframework" ]]; then
    missing=1
    break
  fi
done
if [[ "$missing" -eq 0 ]]; then
  echo "XCFrameworks ready: ${DEST}"
else
  IOS="$(cd "${DEMO}/../../ios" && pwd)"
  if [[ ! -f "${IOS}/scripts/build_xcframeworks.sh" ]]; then
    echo "ERROR: ${DEST} incomplete, and SDK project not found at ${IOS}" >&2
    echo "请向内部索取已打包的 XCFrameworks，或在完整仓库内执行 SDK 发版。" >&2
    exit 1
  fi
  echo "XCFrameworks missing — build + sync from ${IOS}"
  bash "${IOS}/scripts/build_xcframeworks.sh"
  bash "${IOS}/scripts/sync_demo_xcframeworks.sh"
fi
bash "$(dirname "$0")/ensure_peer_sdks.sh"
