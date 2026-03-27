#!/bin/bash

set -e

PROJECT_PATH="$(git rev-parse --show-toplevel)"
$PROJECT_PATH/bin/swiftformat .

if [[ `git status --porcelain --untracked-files=no` ]]; then
    echo "ERROR: Code style issues found. Please run swiftformat locally and commit the changes."
    git diff --stat
    exit 1
else
    echo "Code style check passed"
fi
