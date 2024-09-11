#!/bin/bash

set -euo pipefail

main() {
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    CHECK_INTEGRATION_DIR="$ROOT_DIR/scripts/check-integrations/cocoapods"
    create_podfile ${1}
    install_pods
    build_check_integration
}

create_podfile() {
    local vkid_version="'${1}'"
    echo "
    platform :ios, '12.0'
    project '$CHECK_INTEGRATION_DIR/CheckCocoaPodsIntegration/CheckCocoaPodsIntegration.xcodeproj'
    target 'CheckCocoaPodsIntegration' do
        use_frameworks!
        pod 'VKID', $vkid_version
    end
" > "$CHECK_INTEGRATION_DIR/CheckCocoaPodsIntegration/Podfile"
}

install_pods() {
    bundle exec pod install --repo-update --project-directory="$CHECK_INTEGRATION_DIR/CheckCocoaPodsIntegration"
}

build_check_integration() {
    cd "$CHECK_INTEGRATION_DIR/CheckCocoaPodsIntegration"
    xcodebuild -workspace "CheckCocoaPodsIntegration.xcworkspace" -scheme "CheckCocoaPodsIntegration" -sdk iphonesimulator build
    cd $ROOT_DIR
}

main "$@"
