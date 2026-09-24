#!/usr/bin/env bash
# Selects the newest Xcode 26.x and an "iPhone 16" simulator on the newest iOS 26.x runtime.
# Writes XCODE_APP, SIM_RUNTIME and SIM_UDID to $GITHUB_ENV (or prints them when run locally).
set -euo pipefail

XCODE_APP=$(ls -d /Applications/Xcode_26*.app | sort -V | tail -1)
sudo xcode-select -s "$XCODE_APP/Contents/Developer"
xcodebuild -version

RUNTIMES_JSON=$(xcrun simctl list runtimes available -j)
SIM_RUNTIME=$(python3 - "$RUNTIMES_JSON" <<'PY'
import json, sys
runtimes = json.loads(sys.argv[1])["runtimes"]
ios26 = [r for r in runtimes if r.get("platform") == "iOS" and r["version"].startswith("26.") and r.get("isAvailable", True)]
ios26.sort(key=lambda r: [int(x) for x in r["version"].split(".")])
print(ios26[-1]["identifier"])
PY
)

DEVICES_JSON=$(xcrun simctl list devices available -j)
SIM_UDID=$(python3 - "$DEVICES_JSON" "$SIM_RUNTIME" <<'PY'
import json, sys
devices = json.loads(sys.argv[1])["devices"].get(sys.argv[2], [])
match = [d for d in devices if d["name"] == "iPhone 16"]
print(match[0]["udid"] if match else "")
PY
)
if [ -z "$SIM_UDID" ]; then
  SIM_UDID=$(xcrun simctl create "iPhone 16" com.apple.CoreSimulator.SimDeviceType.iPhone-16 "$SIM_RUNTIME")
fi

echo "Xcode:   $XCODE_APP"
echo "Runtime: $SIM_RUNTIME"
echo "UDID:    $SIM_UDID"
if [ -n "${GITHUB_ENV:-}" ]; then
  {
    echo "XCODE_APP=$XCODE_APP"
    echo "SIM_RUNTIME=$SIM_RUNTIME"
    echo "SIM_UDID=$SIM_UDID"
  } >> "$GITHUB_ENV"
fi
