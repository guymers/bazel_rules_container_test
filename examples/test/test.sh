#!/bin/bash
set -e

cd project
npm install > /dev/null
node index.js
