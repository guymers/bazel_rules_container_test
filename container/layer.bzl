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
"""Open Container Initiative Image Format support for Bazel

These rules are used for building [OCI images](https://github.com/opencontainers/image-spec).

The `container_image` rule constructs a tarball which conforms to [v0.2.0](https://github.com/opencontainers/image-spec/blob/v0.2.0/serialization.md)
of the OCI Image Specification. Currently [Docker](https://docker.com) is the
only container runtime which is able to load these images.

Each image can contain multiple layers which can be created via the
`container_layer` rule.
"""

# Filetype to restrict inputs
tar_filetype = [".tar", ".tar.gz", ".tgz", ".tar.xz"]
deb_filetype = [".deb", ".udeb"]

layer_filetype = [".layer"]


def _short_path_dirname(path):
  """Returns the directory's name of the short path of an artifact."""
  sp = path.short_path
  last_sep = sp.rfind("/")
  if last_sep == -1:
    return ""  # The artifact is at the top level.

  return sp[:last_sep]


def _dest_path(f, strip_prefix):
  """Returns the short path of f, stripped of strip_prefix."""
  if not strip_prefix:
    # If no strip_prefix was specified, use the package of the
    # given input as the strip_prefix.
    strip_prefix = _short_path_dirname(f)
  if f.short_path.startswith(strip_prefix):
    return f.short_path[len(strip_prefix):]
  return f.short_path


def _compute_data_path(out, data_path):
  """Compute the relative data path prefix from the data_path attribute."""
  if data_path:
    # Strip ./ from the beginning if specified.
    # There is no way to handle .// correctly (no function that would make
    # that possible and Skylark is not turing complete) so just consider it
    # as an absolute path. A data_path of / should preserve the entire
    # path up to the repository root.
    if data_path == "/":
      return data_path
    if len(data_path) >= 2 and data_path[0:2] == "./":
      data_path = data_path[2:]
    if not data_path or data_path == ".":  # Relative to current package
      return _short_path_dirname(out)
    elif data_path[0] == "/":  # Absolute path
      return data_path[1:]
    else:  # Relative to a sub-directory
      return _short_path_dirname(out) + "/" + data_path
  return data_path


def _sha256(ctx, artifact):
  """Create an action to compute the SHA-256 of an artifact."""
  out = ctx.new_file(artifact.basename + ".sha256")
  ctx.action(
      executable=ctx.executable._sha256,
      arguments=[artifact.path, out.path],
      inputs=[artifact],
      outputs=[out],
      mnemonic="SHA256"
      )
  return out


def _build_layer(ctx):
  # Compute the relative path
  data_path = _compute_data_path(ctx.outputs.layer, ctx.attr.data_path)

  layer = ctx.new_file(ctx.label.name + ".layer")
  args = [
      "--output=" + layer.path,
      "--directory=" + ctx.attr.directory,
      "--mode=" + ctx.attr.mode,
      ]
  args += ["--file=%s=%s" % (f.path, _dest_path(f, data_path)) for f in ctx.files.files]
  args += ["--tar=" + f.path for f in ctx.files.tars]
  args += ["--deb=" + f.path for f in ctx.files.debs if f.path.endswith(".deb")]
  args += ["--link=%s:%s" % (k, ctx.attr.symlinks[k]) for k in ctx.attr.symlinks]

  arg_file = ctx.new_file(ctx.label.name + ".layer.args")
  ctx.file_action(arg_file, "\n".join(args))

  ctx.action(
      executable=ctx.executable._build_layer,
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
    files=set([ctx.outputs.layer]),
    layer={"name": layer_sha, "layer": layer}
  )


def _container_layer_impl(ctx):
  layer = _build_layer(ctx)
  return _container_layer(ctx, layer)


container_layer = rule(
  implementation=_container_layer_impl,
  attrs={
    "data_path": attr.string(),
    "directory": attr.string(default="/"),
    "tars": attr.label_list(allow_files=tar_filetype),
    "debs": attr.label_list(allow_files=deb_filetype),
    "files": attr.label_list(allow_files=True),
    "mode": attr.string(default="0555"),
    "symlinks": attr.string_dict(),
    "_build_layer": attr.label(
      default=Label("@bazel_tools//tools/build_defs/pkg:build_tar"),
      cfg="host",
      executable=True,
      allow_files=True),
    "_sha256": attr.label(
      default=Label("@bazel_tools//tools/build_defs/hash:sha256"),
      cfg="host",
      executable=True,
      allow_files=True)
  },
  outputs={
    "layer": "%{name}.layer",
    "sha": "%{name}.layer.sha256",
  }
)
"""Create a tarball that can be used as a layer in a container image.

Args:
  data_path: The directory structure from the files is preserved inside the
    layer but a prefix path determined by `data_path` is removed from the
    directory structure. This path can be absolute from the workspace root if
    starting with a `/` or relative to the rule's directory. A relative path
    may start with "./" (or be ".") but cannot go up with "..". By default, the
    `data_path` attribute is unused and all files are supposed to have no
    prefix.
  directory: The directory in which to expand the specified files, defaulting
    to '/'. Only makes sense accompanying one of files/tars/debs.
  tars: A list of tar files whose content should be in the layer.
  debs: A list of Debian packages that will be extracted into the layer.
  files: A list of files that should be included in the layer.
  mode: Set the mode of files added by the `files` attribute.
  symlinks: Symlinks between files in the layer
    ```{ "/path/to/link": "/path/to/target" }```

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
"""


def _container_layer_symlink_fix_impl(ctx):
  renames = {
    "/bin": "/usr/bin",
    "/lib": "/usr/lib",
    "/lib32": "/usr/lib32",
    "/lib64": "/usr/lib64",
    "/libx32": "/usr/libx32",
    "/sbin": "/usr/sbin",
  }

  layer = ctx.new_file(ctx.label.name + ".layer")
  args = [
    "--output=" + layer.path,
    "--src=" + ctx.file.layer.path,
    ]
  args += ["--rename=%s:%s" % (k, renames[k]) for k in renames]

  arg_file = ctx.new_file(ctx.label.name + ".layer.args")
  ctx.file_action(arg_file, "\n".join(args))

  ctx.action(
    executable=ctx.executable._fix_layer,
    arguments=["--flagfile=" + arg_file.path],
    inputs=[ctx.file.layer] + [arg_file],
    outputs=[layer],
    use_default_shell_env=True,
    mnemonic="ContainerLayerSymlinkFix"
  )
  return _container_layer(ctx, layer)


container_layer_debian_stretch_symlink_fix = rule(
  implementation=_container_layer_symlink_fix_impl,
  attrs={
    "layer": attr.label(allow_files=layer_filetype, single_file=True, mandatory=True),
    "_fix_layer": attr.label(
      default=Label("//container:fix_layer"),
      cfg="host",
      executable=True,
      allow_files=True),
    "_sha256": attr.label(
      default=Label("@bazel_tools//tools/build_defs/hash:sha256"),
      cfg="host",
      executable=True,
      allow_files=True)
  },
  outputs={
    "layer": "%{name}.layer",
    "sha": "%{name}.layer.sha256",
  }
)
"""Fix a layer so it works correctly on top of a Debian Stretch base image.

   Debian Stretch has symlinks from bin, lib, lib32, lib64, libx32 and sbin to
   /usr. Some deb files write directly to these symlink-ed folders which causes
   The symlink to be overridden.

Args:
  layer: A container layer to fix.

Outputs:
  layer: The tarball that represents a container layer

Example:
  ```python
  load("@bazel_rules_container//container:layer.bzl", "container_layer_symlink_fix")

  container_layer_symlink_fix(
      name = "files_fixed",
      layer = ":files",
  )
  ```
"""


def _container_layer_from_tar_impl(ctx):
  layer = ctx.new_file(ctx.label.name + ".layer")
  ctx.action(
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
    "tar": attr.label(allow_files=tar_filetype, single_file=True, mandatory=True),
    "_sha256": attr.label(
      default=Label("@bazel_tools//tools/build_defs/hash:sha256"),
      cfg="host",
      executable=True,
      allow_files=True)
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
