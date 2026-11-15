#!/usr/bin/env bash
set -euo pipefail

device="${1:-booted}"
source_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT
app="$build_dir/MicProbe.app"
mkdir "$app"
cp "$source_dir/MicProbe-Info.plist" "$app/Info.plist"
xcrun --sdk iphonesimulator swiftc -target "$(uname -m)-apple-ios16.0-simulator" \
    -sdk "$(xcrun --sdk iphonesimulator --show-sdk-path)" -parse-as-library \
    "$source_dir/MicProbe.swift" -o "$app/MicProbe"
xattr -cr "$app"
codesign --force --sign - "$app"
xcrun simctl install "$device" "$app"
