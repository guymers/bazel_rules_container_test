#!/bin/bash
set -e

bazel build //docs
unzip -o bazel-bin/docs/docs-skydoc.zip
echo '' > README.md
cat container.md >> README.md
cat pull.md >> README.md
cat test.md >> README.md
rm container.md pull.md test.md
