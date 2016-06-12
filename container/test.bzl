# Copyright 2015 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Based on Jsonnet jsonnet_to_json_test"""

container_filetype = FileType([".tar"])

_EXIT_CODE_COMPARE_COMMAND = """
EXIT_CODE=$?
EXPECTED_EXIT_CODE=%d
if [ $EXIT_CODE -ne $EXPECTED_EXIT_CODE ] ; then
  echo "FAIL (exit code): %s"
  echo "Expected: $EXPECTED_EXIT_CODE"
  echo "Actual: $EXIT_CODE"
  echo "Output: $OUTPUT"
  exit 1
fi
"""

_DIFF_COMMAND = """
GOLDEN=$(cat %s)
if [ "$OUTPUT" != "$GOLDEN" ]; then
  echo "FAIL (output mismatch): %s"
  echo "Diff:"
  diff <(echo $GOLDEN) <(echo $OUTPUT)
  echo "Expected: $GOLDEN"
  echo "Actual: $OUTPUT"
  exit 1
fi
"""

_REGEX_DIFF_COMMAND = """
GOLDEN_REGEX=$(cat %s)
if [[ ! "$OUTPUT" =~ $GOLDEN_REGEX ]]; then
  echo "FAIL (regex mismatch): %s"
  echo "Output: $OUTPUT"
  exit 1
fi
"""


def _get_runfile_path(ctx, f):
  """Return the runfiles relative path of f."""
  if ctx.workspace_name:
    return ctx.workspace_name + "/" + f.short_path
  else:
    return f.short_path


def _container_test_impl(ctx):
  golden_files = []
  diff_command = ""
  if ctx.file.golden:
    golden_files += [ctx.file.golden]
    if ctx.attr.regex:
      diff_command = _REGEX_DIFF_COMMAND % (ctx.file.golden.short_path, ctx.label.name)
    else:
      diff_command = _DIFF_COMMAND % (ctx.file.golden.short_path, ctx.label.name)

  daemon = "false"
  if ctx.attr.daemon:
    daemon = "true"

  images = getattr(ctx.attr.image, "partial_images", [])
  image = images[-1]

  ctx.template_action(
    template=ctx.file.test_container_template,
    substitutions={
      "%{daemon}": daemon,
      "%{mem_limit}": ctx.attr.mem_limit,
      "%{image_name}": _get_runfile_path(ctx, image["name"]),
      "%{load_statements}": "\n".join(
        [
          "incr_load '%s' '%s'" % (_get_runfile_path(ctx, i["name"]),
                                   _get_runfile_path(ctx, i["image"]))
          for i in images]
      ),
      "%{test_script}": _get_runfile_path(ctx, ctx.file.test),
      "%{test_files}": " ".join(["%s" % (_get_runfile_path(ctx, f)) for f in ctx.files.files]),
      "%{exit_code_compare_command}": _EXIT_CODE_COMPARE_COMMAND % (ctx.attr.error, ctx.label.name),
      "%{diff_command}": diff_command,
    },
    output=ctx.outputs.executable,
    executable=True
  )

  image_inputs = [i["name"] for i in images] + [i["image"] for i in images]
  test_inputs = [ctx.file.image] + [ctx.file.test] + ctx.files.files + golden_files
  runfiles = ctx.runfiles(files=image_inputs + test_inputs, collect_data=True)
  return struct(runfiles=runfiles)


container_test = rule(
  _container_test_impl,
  attrs={
    "image": attr.label(allow_files=container_filetype, single_file=True),
    "daemon": attr.bool(),
    "mem_limit": attr.string(),
    "test": attr.label(allow_files=True, single_file=True),
    "files": attr.label_list(allow_files=True),
    "golden": attr.label(allow_files=True, single_file=True),
    "error": attr.int(),
    "regex": attr.bool(),
    "test_container_template": attr.label(
      default=Label("//container:docker_test_container_template"),
      single_file=True,
      allow_files=True),
  },
  executable=True,
  test=True,
)
"""Experimental container testing.

Does not work with sandboxing enabled.

Args:
  image: The image to run tests on.
  daemon: Whether to run the container as a daemon or execute the test inside.
  mem_limit: Memory limit to add to the container.
  test: Test script to run.
  files: Any files that the test script might require.
  golden: The expected output.
  error: The expected error code.
  regex: Set to 1 if `golden` contains a regex to match against the output.
  test_container_template: Internal attribute

Example:
  ```python
  load("@bazel_rules_container//container:test.bzl", "container_test")

  container_test(
      name = "nodejs",
      size = "small",
      files = [
          "project/index.js",
          "project/package.json",
      ],
      golden = "output.txt",
      image = "//nodejs",
      test = "test.sh",
  )
  ```
"""
