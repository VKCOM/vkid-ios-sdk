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
    -configuration Debug \
    -sdk iphonesimulator \
    CLIENT_ID=$VKID_DEMO_IOS_CLIENT_ID CLIENT_SECRET=$VKID_DEMO_IOS_CLIENT_SECRET
}

test_without_building() {
    xcodebuild test-without-building \
    -project ${1} \
    -scheme ${2} \
    -destination "platform=iOS Simulator,id=${3},OS=17.0" \
    -resultBundlePath ${4}
}

# Allure results

generate_allure_results() {
    echo "Exporting allure results..."
    local xcresults_tool_path=${1}
    local xcresult_artifact_path=${2}
    local allure_results_folder=${3}
    $xcresults_tool_path export $xcresult_artifact_path $allure_results_folder
}

SIM_ID=""

main() {
    local src_root="$(git rev-parse --show-toplevel)"
    local project_path=$src_root/VKIDDemo/VKIDDemo.xcodeproj
    local scheme="VKIDDemo"
    local sim_name="VKIDTestSimulator"
    local xcresult_artifact_path=$src_root/build-artifacts/VKID.xcresult
    local xcresults_tool_path=$src_root/bin/xcresults
    local allure_results_folder=$src_root/allure-results

    rm -rf $xcresult_artifact_path

    local sim_id=$(find_simulator $sim_name)
    if [ ! -n "$sim_id" ]; then
        sim_id=$(create_simulator $sim_name)
    fi

    SIM_ID=$sim_id
    boot_simulator $sim_id || true
    build_for_testing $project_path $scheme
    test_without_building $project_path $scheme $sim_id $xcresult_artifact_path
    generate_allure_results $xcresults_tool_path $xcresult_artifact_path $allure_results_folder
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
