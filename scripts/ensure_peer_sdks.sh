#!/usr/bin/env bash
# 把已接 ADN 的对方 SDK 备到对外 Demo/ThirdParty，打开就能出广告。
# 已接：JD / AdGain / Ltmb。不接 Dusk / Sigmob / Mintegral。
set -euo pipefail
DEMO="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${DEMO}/ThirdParty"
IOS="$(cd "${DEMO}/../../ios" && pwd)"
JINDAI_SRC="$(cd "${DEMO}/../../../adapter/SDKDemo/SDK" && pwd)"

mkdir -p "${DEST}"

copy_dir() {
  local src="$1" dest="$2" name="$3"
  if [[ -d "${dest}" ]]; then
    echo "OK ${name} already at ${dest}"
    return 0
  fi
  if [[ ! -d "${src}" ]]; then
    echo "WARN: missing ${src} (${name})" >&2
    return 1
  fi
  mkdir -p "$(dirname "${dest}")"
  cp -R "${src}" "${dest}"
  echo "copied ${name} -> ${dest}"
}

# AdGain / LiteMob：优先吃对内 ThirdParty，没有再 fetch
if [[ ! -d "${DEST}/AdGainSDK-current/AdGainSDK.xcframework" ]]; then
  if [[ -d "${IOS}/ThirdParty/AdGainSDK-current/AdGainSDK.xcframework" ]]; then
    copy_dir "${IOS}/ThirdParty/AdGainSDK-current" "${DEST}/AdGainSDK-current" "AdGain"
  elif [[ -f "${IOS}/scripts/fetch_adgain_ios.sh" ]]; then
    bash "${IOS}/scripts/fetch_adgain_ios.sh"
    copy_dir "${IOS}/ThirdParty/AdGainSDK-current" "${DEST}/AdGainSDK-current" "AdGain"
  else
    echo "ERROR: AdGainSDK 不在仓内，且无法 fetch。请向内部索取 ThirdParty/AdGainSDK-current" >&2
    exit 1
  fi
fi

if [[ ! -d "${DEST}/LitemobSDK-current/LitemobSDK.xcframework" ]]; then
  if [[ -d "${IOS}/ThirdParty/LitemobSDK-current/LitemobSDK.xcframework" ]]; then
    copy_dir "${IOS}/ThirdParty/LitemobSDK-current" "${DEST}/LitemobSDK-current" "Litemob"
  elif [[ -f "${IOS}/scripts/fetch_litemob_ios.sh" ]]; then
    bash "${IOS}/scripts/fetch_litemob_ios.sh"
    copy_dir "${IOS}/ThirdParty/LitemobSDK-current" "${DEST}/LitemobSDK-current" "Litemob"
  else
    echo "ERROR: LitemobSDK 不在仓内，且无法 fetch。请向内部索取 ThirdParty/LitemobSDK-current" >&2
    exit 1
  fi
fi

if [[ ! -d "${DEST}/JinDaiSDK-current/JinDaiSDK.framework" ]]; then
  if [[ -d "${JINDAI_SRC}/JinDaiSDK.framework" ]]; then
    copy_dir "${JINDAI_SRC}" "${DEST}/JinDaiSDK-current" "JinDai"
  else
    echo "WARN: 没有 JinDaiSDK（adapter/SDKDemo/SDK）。JD 层会 missing，AdGain/Ltmb 仍可出广告。" >&2
  fi
fi

echo "peer SDKs ready: ${DEST}"
ls -1 "${DEST}"
