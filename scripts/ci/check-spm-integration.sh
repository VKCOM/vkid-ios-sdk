#!/bin/bash

set -euo pipefail

main() {
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    local vkid_version="${1}"
    cd "$ROOT_DIR/scripts/check-integrations/spm/"
    sed -i '' "s/from: \".*\"/from: \"$vkid_version\"/" "Package.swift"
    xcodebuild -scheme CheckSPMIntegration -destination "platform=iOS Simulator,name=Any iOS Simulator Device" -sdk iphonesimulator build
    cd "$ROOT_DIR"
}

main "$@"
