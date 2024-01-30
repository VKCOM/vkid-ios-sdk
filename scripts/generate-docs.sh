#!/bin/bash

# Need to start the script from the workspace directory.

set -euo pipefail

echo "Cleaning Documentation folder..."
rm -rf docs/

echo "Building static hosting documentation for VKID..."
xcodebuild clean docbuild \
    -scheme VKID \
    -sdk iphoneos \
    -destination generic/platform=iOS \
    -configuration Release \
    OTHER_DOCC_FLAGS="--transform-for-static-hosting --hosting-base-path vkid-ios-sdk --output-path docs/" \