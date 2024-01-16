#!/bin/bash

# Simulator management
find_simulator() {
    xcrun simctl list devices | \
    grep ${1} | \
    grep -E -o -i "([0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12})" | \
    head -n 1
}

create_simulator() {
    xcrun simctl create ${1} "iPhone 15"
}

delete_simulator() {
    xcrun simctl delete ${1}
}

boot_simulator() {
    xcrun simctl boot ${1}
}

shutdown_simulator() {
    xcrun simctl shutdown ${1}
}

# Build
build_for_testing() {
    xcodebuild clean build-for-testing \
    -project ${1} \
    -scheme ${2} \
    -sdk iphonesimulator \
    CLIENT_ID=$VKID_DEMO_IOS_CLIENT_ID CLIENT_SECRET=$VKID_DEMO_IOS_CLIENT_SECRET
}

test_without_building() {
    xcodebuild test-without-building \
    -project ${1} \
    -scheme ${2} \
    -destination "platform=iOS Simulator,id=${3},OS=17.0"
}

SIM_ID=""

main() {
    local src_root="$(git rev-parse --show-toplevel)"
    local project_path=$src_root/VKIDDemo/VKIDDemo.xcodeproj
    local scheme="VKIDDemo"
    local sim_name="VKIDTestSimulator"

    local sim_id=$(find_simulator $sim_name)
    if [ ! -n "$sim_id" ]; then
        sim_id=$(create_simulator $sim_name)
    fi

    SIM_ID=$sim_id
    boot_simulator $sim_id
    build_for_testing $project_path $scheme
    test_without_building $project_path $scheme $sim_id
    shutdown_simulator $sim_id
    delete_simulator $sim_id
    SIM_ID=""
}

cleanup() {
    [ -n "$SIM_ID" ] && delete_simulator $SIM_ID
}

set -euo pipefail
# trap cleanup EXIT
main "$@"
