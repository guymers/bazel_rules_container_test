#!/bin/bash
set -e

bazel build //docs
unzip -o bazel-bin/docs/docs-skydoc.zip
echo '' > README.md
cat container/layer.md >> README.md
cat container/image.md >> README.md
cat container/pull.md >> README.md
cat container/test.md >> README.md
rm container/layer.md container/image.md container/pull.md container/test.md index.md
