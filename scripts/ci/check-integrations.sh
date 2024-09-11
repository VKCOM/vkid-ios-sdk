#!/bin/bash
# Root script for starting check integrations

set -euo pipefail

main() {
    ROOT_DIR="$(git rev-parse --show-toplevel)"
    source "$ROOT_DIR/scripts/ci/check-cocoapods-integration.sh" ${1}
    source "$ROOT_DIR/scripts/ci/check-spm-integration.sh" ${1}
}

main "$@"
