#!/bin/bash

set -euo pipefail

bundle exec pod trunk push VKIDCore.podspec
bundle exec pod trunk push VKID.podspec --synchronous
