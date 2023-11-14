#!/bin/bash

set -e

PROJECT_PATH="$(git rev-parse --show-toplevel)"
$PROJECT_PATH/bin/swiftformat .
if [[ `git status --porcelain --untracked-files=no` ]]; then
  git commit -a -m "Code style auto formatting"
  git push
else
  echo "No changes to commit"
fi
