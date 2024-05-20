#!/bin/bash

set -ex

mkdir .health-metrics || true
sh scripts/ci/build-for-testing.sh
pushd scripts/danger-tooling
swift run metrics-collector
popd
