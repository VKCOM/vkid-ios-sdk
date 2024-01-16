#!/bin/bash

set -euo pipefail

main() {
    local new_version=${1}

    if ! is_valid_semver $new_version; then
        echo "ERROR: $new_version isn't a valid semantic versioning"
        exit 1
    fi

    ROOT_DIR="$(git rev-parse --show-toplevel)"
    VERSION_FILE="$ROOT_DIR/VKID/Sources/Infrastructure/Versions.swift"
    VKID_CURRENT_VERSION="$(grep_current_version $VERSION_FILE)"

     if [ "$new_version" == "$VKID_CURRENT_VERSION" ]; then
         echo "ERROR: New version is the same as the current version"
         exit 1
     fi

    echo "Changing sdk version from $VKID_CURRENT_VERSION to $new_version"

    bump_version_in_version_file $new_version
    bump_version_in_podspecs $new_version

    echo "SDK version successfully changed to $new_version"
}

grep_current_version() {
    local version_file=${1}
    echo $(grep -Eo 'VKID_VERSION = "[^"]*"' "$version_file") | awk -F'"' '{print $2}'
}

is_valid_semver() {
    if ! [[ ${1:-} =~ ^([0-9]{1}|[1-9][0-9]+)\.([0-9]{1}|[1-9][0-9]+)\.([0-9]{1}|[1-9][0-9]+)($|[-+][0-9A-Za-z+.-]+$) ]]; then
        false
        return
    fi
}

bump_version_in_version_file() {
    local new_version=${1}

    sed -i '' "s/$VKID_CURRENT_VERSION/$new_version/" "$VERSION_FILE"
}

bump_version_in_podspecs() {
    local podspecs=(
        "$ROOT_DIR/VKIDCore.podspec"
        "$ROOT_DIR/VKID.podspec"
    )
    local new_version=${1}

    for spec in "${podspecs[@]}"; do
        sed -i '' 's/spec.version = "[^"]*"/spec.version = "'$new_version'"/' "$spec"
    done
}

main "$@"
