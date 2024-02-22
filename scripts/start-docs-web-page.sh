#!/bin/bash

# Script starts docs webpage on localhost.
# Need to start the script from the workspace directory.

set -euo pipefail

port=4000
websitePath=vkid-ios-sdk

gem install jekyll -v 4.3.3 
gem install bundler -v 2.5.4
rm -rf .tmp_server_build
jekyll new .tmp_server_build
cd .tmp_server_build
mkdir docs
cp -R ../docs/. docs
mv docs vkid-ios-sdk
echo "\nbasewebsite: /${websitePath}" >> _config.yml
bash -c 'sleep 5; open -a Safari http://localhost:'"$port"'/'"$websitePath"'/documentation/vkid/' &
bundle exec jekyll serve --port ${port}

