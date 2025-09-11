#!/bin/bash

set -euo pipefail

core_push_command="bundle exec pod trunk push VKIDCore.podspec $@"
vkid_push_command="bundle exec pod trunk push VKID.podspec --synchronous $@"

eval $core_push_command
eval $vkid_push_command
