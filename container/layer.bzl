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
"""Layers

Open Container Initiative Image Format support for Bazel

These rules are used for building [OCI images](https://github.com/opencontainers/image-spec).

Each image can contain multiple layers which can be created via the
`container_layer` rule.
"""

load(
  "@bazel_tools//tools/build_defs/hash:hash.bzl",
  _sha256 = "sha256",
)

layer_filetype = [".layer"]


def _build_layer(ctx):
  layer = ctx.actions.declare_file(ctx.label.name + ".layer")
  args = [
    "--output=" + layer.path,
    "--directory=" + ctx.attr.directory,
    "--mode=" + ctx.attr.mode,
  ]
  args += ["--file=%s=%s" % (f.path, f.basename) for f in ctx.files.files]
  args += ["--tar=" + f.path for f in ctx.files.tars]
  args += ["--deb=" + f.path for f in ctx.files.debs]
  args += ["--link=%s:%s" % (k, ctx.attr.symlinks[k]) for k in ctx.attr.symlinks]

  arg_file = ctx.actions.declare_file(ctx.label.name + ".layer.args")
  ctx.actions.write(arg_file, "\n".join(args))

  ctx.actions.run(
    executable=ctx.executable._build_tar,
    arguments=["--flagfile=" + arg_file.path],
    inputs=ctx.files.files + ctx.files.tars + ctx.files.debs + [arg_file],
    outputs=[layer],
    use_default_shell_env=True,
    mnemonic="ContainerLayer"
  )
  return layer


def _container_layer(ctx, layer):
  layer_sha = _sha256(ctx, layer)
  return struct(
    runfiles=ctx.runfiles(files=[ctx.outputs.layer, ctx.outputs.sha]),
    files=depset([ctx.outputs.layer]),
    layer={
      "name": layer_sha,
      "layer": layer,
    }
  )


def _container_layer_impl(ctx):
  layer = _build_layer(ctx)
  return _container_layer(ctx, layer)


container_layer = rule(
  doc = """
Create a tarball that can be used as a layer in a container image.

Outputs:
  layer: The tarball that represents a container layer

Example:
  ```python
  load("@bazel_rules_container//container:layer.bzl", "container_layer")

  filegroup(
      name = "nodejs_debs",
      srcs = [
          "nodejs.deb",
          "libgdbm3.deb",
          "perl.deb",
          "perl_modules.deb",
          "rlwrap.deb",
      ],
  )

  container_layer(
      name = "nodejs_files",
      debs = [":nodejs_debs"],
      symlinks = { "/usr/bin/node": "/usr/bin/nodejs" },
  )
  ```
""",
  implementation=_container_layer_impl,
  attrs={
    "directory": attr.string(
      doc = "The directory in which to expand the specified files, defaulting to '/'. Only makes sense accompanying one of files/tars/debs.",
      default = "/"
    ),
    "tars": attr.label_list(
      doc = "A list of tar files whose content should be in the layer.",
      allow_files = True
    ),
    "debs": attr.label_list(
      doc = "A list of Debian packages that will be extracted into the layer.",
      allow_files = True
    ),
    "files": attr.label_list(
      doc = "A list of files that should be included in the layer.",
      allow_files = True
    ),
    "mode": attr.string(
      doc = "Set the mode of files added by the `files` attribute.",
      default = "0555"
    ),
    "symlinks": attr.string_dict(
      doc = """Symlinks between files in the layer ```{ "/path/to/link": "/path/to/target" }```"""
    ),
    "_build_tar": attr.label(
      default=Label("@bazel_tools//tools/build_defs/pkg:build_tar"),
      cfg="host",
      executable=True,
      allow_files=True
    ),
    "sha256": attr.label(
      default = Label("@bazel_tools//tools/build_defs/hash:sha256"),
      cfg = "host",
      executable = True,
      allow_files = True,
    ),
  },
  outputs={
    "layer": "%{name}.layer",
    "sha": "%{name}.layer.sha256",
  }
)


def _container_layer_from_tar_impl(ctx):
  layer = ctx.actions.declare_file(ctx.label.name + ".layer")
  ctx.actions.run_shell(
    command='cp "' + ctx.file.tar.path + '" "' + layer.path + '"',
    inputs=[ctx.file.tar],
    outputs=[layer],
    use_default_shell_env=True,
    mnemonic="ContainerLayerFromTar"
  )
  return _container_layer(ctx, layer)


container_layer_from_tar = rule(
  implementation=_container_layer_from_tar_impl,
  attrs={
    "tar": attr.label(allow_single_file=True, mandatory=True),
    "sha256": attr.label(
      default = Label("@bazel_tools//tools/build_defs/hash:sha256"),
      cfg = "host",
      executable = True,
      allow_files = True,
    ),
  },
  outputs={
    "layer": "%{name}.layer",
    "sha": "%{name}.layer.sha256",
  }
)
"""Uses an existing tarball as a layer in a container image.

Args:
  tar: A tar file that will be the layer.

Outputs:
  layer: The tarball represented as a container layer

Example:
  ```python
  load("@bazel_rules_container//container:layer.bzl", "container_layer_from_tar")

  genrule(
    name = "jessie_tar",
    srcs = ["@debian_jessie//file"],
    outs = ["jessie_extracted.tar"],
    cmd = "cat $< | xzcat >$@",
  )

  container_layer_from_tar(
      name = "jessie",
      tar = ":jessie_tar",
  )
  ```
"""
