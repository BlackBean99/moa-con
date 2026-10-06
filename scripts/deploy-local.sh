#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"
mode="${1:---simulator}"
mkdir -p artifacts/usability
case "$mode" in
  --simulator)
    simulator_id="${2:-D843BD0C-6CB9-4444-817C-E45B00736225}"
    build_path="${MOACON_BUILD_PATH:-/tmp/moacon-local-release-sim}"
    xcrun simctl boot "$simulator_id" 2>/dev/null || true
    xcrun simctl bootstatus "$simulator_id" -b
    xcodebuild -project GifticonCollector.xcodeproj -scheme GifticonCollector \
      -configuration Release -destination "platform=iOS Simulator,id=$simulator_id" \
      -derivedDataPath "$build_path" build > artifacts/usability/simulator-release-build.log 2>&1
    product="$build_path/Build/Products/Release-iphonesimulator/GifticonCollector.app"
    xcrun simctl install "$simulator_id" "$product"
    xcrun simctl launch "$simulator_id" com.yourteam.gifticoncollector
    ditto -c -k --keepParent "$product" artifacts/usability/Moacon-Simulator-0.2.zip
    ;;
  --device)
    device_id="${2:-00008140-001809CA18A2201C}"
    build_path="${MOACON_BUILD_PATH:-/tmp/moacon-local-release-device}"
    xcodebuild -project GifticonCollector.xcodeproj -scheme GifticonCollector \
      -configuration Release -destination "id=$device_id" -allowProvisioningUpdates \
      -derivedDataPath "$build_path" build > artifacts/usability/device-build.log 2>&1
    product="$build_path/Build/Products/Release-iphoneos/GifticonCollector.app"
    xcrun devicectl device install app --device "$device_id" "$product"
    xcrun devicectl device process launch --device "$device_id" com.yourteam.gifticoncollector
    ;;
  *) printf 'Usage: %s --simulator|--device [device-id]\n' "$0" >&2; exit 2 ;;
esac
printf 'Built, installed, and launched: %s\n' "$product"
