#!/bin/bash
set -e
set -o pipefail
readonly DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bazel build //docs
unzip -o "$(bazel info bazel-bin)/docs/docs-skydoc.zip" -d "$DIR"
