#!/bin/bash
set -e

bazel build //nodejs

set +e
bazel test //test/...
readonly test_exit_code=$?

readonly testlogs=$(bazel info bazel-testlogs)
while IFS= read -r -d '' file
do
  echo "$file"
  cat "$file"
  echo ""
done <  <(find "$testlogs" -name test.log -type f -print0)

exit "$test_exit_code"
set -e
