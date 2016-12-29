#!/bin/bash
set -e

cat /etc/debian_version
node -v
echo

cd project
npm install > /dev/null
node index.js
