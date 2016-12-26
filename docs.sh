#!/bin/bash
set -e

bazel build //docs
unzip -o bazel-bin/docs/docs-skydoc.zip
echo '' > README.md
cat container/container.md >> README.md
cat container/pull.md >> README.md
cat container/test.md >> README.md
rm container/container.md container/pull.md container/test.md index.md
