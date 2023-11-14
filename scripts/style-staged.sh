#!/bin/bash

PROJECT_PATH="$(git rev-parse --show-toplevel)"

git diff --diff-filter=d --staged --name-only | grep -e '\(.*\).swift$' | while read line; do
  $PROJECT_PATH/bin/swiftformat "${line}";
  git add "$line";
done
