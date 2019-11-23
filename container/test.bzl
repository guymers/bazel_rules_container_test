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
"""Testing

Based on Jsonnet jsonnet_to_json_test"""

load(
    "@io_bazel_rules_docker//container:layer_tools.bzl",
    _get_layers = "get_from_target",
    _incr_load = "incremental_load",
)
load(
    "@io_bazel_rules_docker//container:providers.bzl",
    "ImageInfo",
    "ImportInfo",
)

_EXIT_CODE_COMPARE_COMMAND = """
readonly EXPECTED_EXIT_CODE=%d
if [ $EXIT_CODE -ne $EXPECTED_EXIT_CODE ]; then
  echo "FAIL (exit code): %s"
  echo "Expected: $EXPECTED_EXIT_CODE"
  echo "Actual: $EXIT_CODE"
  echo "Output:"
  echo "$OUTPUT"
  echo "Log:"
  echo "$LOGS"
  exit 1
fi
"""

_DIFF_COMMAND = """
readonly GOLDEN=$(cat "${RUNFILES}/%s")
if [ "$OUTPUT" != "$GOLDEN" ]; then
  echo "FAIL (output mismatch): %s"
  echo "Diff:"
  diff <(echo "$GOLDEN") <(echo "$OUTPUT")
  echo "Expected:"
  echo "$GOLDEN"
  echo "Actual:"
  echo "$OUTPUT"
  echo "Log:"
  echo "$LOGS"
  exit 2
fi
"""

_REGEX_DIFF_COMMAND = """
readonly GOLDEN_REGEX=$(cat "${RUNFILES}/%s")
if [[ ! "$OUTPUT" =~ "$GOLDEN_REGEX" ]]; then
  echo "FAIL (regex mismatch): %s"
  echo "Output:"
  echo "$OUTPUT"
  echo "Log:"
  echo "$LOGS"
  exit 3
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
      diff_command = _REGEX_DIFF_COMMAND % (_get_runfile_path(ctx, ctx.file.golden), ctx.label.name)
    else:
      diff_command = _DIFF_COMMAND % (_get_runfile_path(ctx, ctx.file.golden), ctx.label.name)

  daemon = "false"
  if ctx.attr.daemon:
    daemon = "true"

  read_only = "false"
  if ctx.attr.read_only:
    read_only = "true"

  volumes = {}
  for i in range(0, len(ctx.attr.volume_mounts)):
    volumes[ctx.attr.volume_mounts[i]] = ctx.files.volume_files[i]

  image = _get_layers(ctx, ctx.label.name, ctx.attr.image)

  # ideally ctx.attr.image[DefaultInfo].executable
  # we dont need a tag but it is required
  tag_name = "bazel_container_test:{}".format(ctx.label.name)
  incr_load_out_file = ctx.actions.declare_file("%s.incr_load" % ctx.attr.name)
  _incr_load(
      ctx,
      { tag_name: ctx.attr.image[ImageInfo].container_parts },
      incr_load_out_file,
      run = False,
      run_flags = None,
  )

  container_template_out_file = ctx.actions.declare_file("%s.test" % ctx.attr.name)
  ctx.actions.expand_template(
    template=ctx.file._test_container_template,
    substitutions={
      "%{daemon}": daemon,
      "%{read_only}": read_only,
      "%{tmpfs_directories}": " ".join(["%s" % v for v in ctx.attr.tmpfs_directories]),
      "%{mem_limit}": ctx.attr.mem_limit,
      "%{env}": " ".join(["%s=%s" % (k, ctx.attr.env[k]) for k in ctx.attr.env]),
      "%{volumes}": " ".join(["%s=%s" % (_get_runfile_path(ctx, volumes[k]), k) for k in volumes]),
      "%{options}": " ".join(["%s" % o for o in ctx.attr.options]),
      "%{image_digest}": _get_runfile_path(ctx, image["config_digest"]),
      "%{test_script}": _get_runfile_path(ctx, ctx.file.test),
      "%{test_files}": " ".join(["%s" % (_get_runfile_path(ctx, f)) for f in ctx.files.files]),
      "%{exit_code_compare_command}": _EXIT_CODE_COMPARE_COMMAND % (ctx.attr.error, ctx.label.name),
      "%{diff_command}": diff_command,
    },
    output=container_template_out_file,
    is_executable=True
  )
  # load the image layers before running the test
  ctx.actions.run_shell(
      inputs=[incr_load_out_file, container_template_out_file],
      outputs=[ctx.outputs.executable],
      command="cat '%s' '%s' > '%s'" % (incr_load_out_file.path, container_template_out_file.path, ctx.outputs.executable.path),
  )

  image_inputs = [
    image["config"],
    image["config_digest"],
  ] + image.get("zipped_layer", []) + image.get("unzipped_layer", []) + image.get("blobsum", []) + image.get("diff_id", [])
  volume_inputs = [v for v in ctx.files.volume_files]
  test_inputs = [ctx.file.image] + [ctx.file.test] + ctx.files.files + golden_files
  runfiles = ctx.runfiles(files=image_inputs + volume_inputs + test_inputs, collect_data=True)
  return struct(runfiles=runfiles)


container_test = rule(
  _container_test_impl,
  attrs={
    "image": attr.label(allow_single_file=True),
    "daemon": attr.bool(),
    "read_only": attr.bool(default=True),
    "tmpfs_directories": attr.string_list(),
    "mem_limit": attr.string(),
    "env": attr.string_dict(),
    "volume_files": attr.label_list(allow_files=True),
    "volume_mounts": attr.string_list(),
    "options": attr.string_list(),
    "test": attr.label(allow_single_file=True),
    "files": attr.label_list(allow_files=True),
    "golden": attr.label(allow_single_file=True),
    "error": attr.int(),
    "regex": attr.bool(),
    "_test_container_template": attr.label(
      default=Label("//container/docker:test_container_template"),
      allow_single_file=True,
    ),
    "incremental_load_template": attr.label(
      default = Label("@io_bazel_rules_docker//container:incremental_load_template"),
      allow_single_file = True,
    ),
  },
  executable=True,
  test=True,
  toolchains = ["@io_bazel_rules_docker//toolchains/docker:toolchain_type"],
)
"""Experimental container testing.

Does not work with sandboxing enabled.

Args:
  image: The image to run tests on.
  daemon: Whether to run the container as a daemon or execute the test by
    running it as the container command.
  read_only: Is the container run in read only mode.
  mem_limit: Memory limit to add to the container.
  env: Dictionary from environment variable names to their values when running
    the container. ```env = { "FOO": "bar", ... }```
  volume_files: List of files to mount.
  volume_mounts: List of mount points that match `volume_mounts`.
  options: Additional options to pass to the container.
  test: Test script to run.
  files: Any files that the test script might require.
  golden: The expected output.
  error: The expected error code.
  regex: Set to 1 if `golden` contains a regex to match against the output.

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
