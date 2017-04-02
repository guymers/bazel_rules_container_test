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

layer_filetype = [".layer"]

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

def _serialize_dict(dict_value):
  return ",".join(["%s=%s" % (k, dict_value[k]) for k in dict_value])


def _create_image_config(ctx, layers):
  """Create the config for the new container image."""
  config = ctx.new_file(ctx.label.name + ".config")

  args = [
      "--output=%s" % config.path,
      ]
  args += ["--port=%s" % p for p in ctx.attr.ports]
  args += ["--env=%s=%s" % (k, ctx.attr.env[k]) for k in ctx.attr.env]
  args += ["--entry-point=%s" % e for e in ctx.attr.entrypoint]
  args += ["--command=%s" % e for e in ctx.attr.cmd]
  args += ["--volume=%s" % v for v in ctx.attr.volumes]
  if ctx.attr.user:
    args += ["--user=" + ctx.attr.user]
  if ctx.attr.workdir:
    args += ["--working-dir=" + ctx.attr.workdir]
  if ctx.attr.labels:
    args += ["--label=%s=%s" % (k, ctx.attr.labels[k]) for k in ctx.attr.labels]

  inputs = [l["name"] for l in layers]
  args += ["--layer=@" + l["name"].path for l in layers]

  base = ctx.file.base
  if base:
    image_config_base = getattr(ctx.attr.base, "image_config")
    if image_config_base:
      args += ["--base=%s" % image_config_base.path]
      inputs += [image_config_base]

  ctx.action(
      executable=ctx.executable._create_image_config,
      arguments=args,
      inputs=inputs,
      outputs=[config],
      use_default_shell_env=True,
      mnemonic="CreateImageConfig"
      )
  return config


def _create_partial_image(ctx, name, config, layers, tags):
  """Create a partial image from the list of layers."""
  args = [
      "--id=@" + name.path,
      "--output=" + ctx.outputs.partial.path,
      "--config=" + config.path,
      ]
  args += ["--tag=%s" % tag for tag in tags]
  args += ["--layer=@%s=%s" % (l["name"].path, l["layer"].path) for l in layers]
  inputs = [name, config] + [l["name"] for l in layers] + [l["layer"] for l in layers]

  base = ctx.file.base
  if base:
    args += ["--base=%s" % base.path]
    inputs += [base]

  ctx.action(
      executable=ctx.executable._create_image,
      arguments=args,
      inputs=inputs,
      outputs=[ctx.outputs.partial],
      mnemonic="CreateImage",
      )


def _assemble_image(ctx, partial_images):
  """Create the full image from the list of layers."""
  images = [l["image"] for l in partial_images]
  args = [
           "--output=" + ctx.outputs.image.path,
         ] + ["--image=" + i.path for i in images]
  ctx.action(
      executable=ctx.executable._assemble_image,
      arguments=args,
      inputs=images,
      outputs=[ctx.outputs.image],
      mnemonic="AssembleImage"
      )


def _container_image_name(ctx):
  if ctx.attr.image_name:
    return ctx.attr.image_name
  return "%s/%s" % ("bazel", ctx.label.package)


def _container_image_tag(ctx):
  if ctx.attr.image_tag:
    return ctx.attr.image_tag
  return ctx.label.name


def _get_runfile_path(ctx, f):
  """Return the runfiles relative path of f."""
  if ctx.workspace_name:
    return ctx.workspace_name + "/" + f.short_path
  else:
    return f.short_path


def _container_image_impl(ctx):
  layers = [getattr(l, "layer") for l in ctx.attr.layers]
  if ctx.file.config_file:
    config = ctx.file.config_file
  else:
    config = _create_image_config(ctx, layers)
  name = _sha256(ctx, config)

  tag = _container_image_name(ctx) + ":" + _container_image_tag(ctx)
  _create_partial_image(ctx, name, config, layers, [tag])

  partial_images = getattr(ctx.attr.base, "partial_images", []) + [{
    "name": name,
    "image": ctx.outputs.partial}
  ]

  # Generate the load script
  ctx.template_action(
    template=ctx.file._incremental_load_template,
    substitutions={
      "%{load_statements}": "\n".join(
        ["incr_load '%s' '%s'" % (
          _get_runfile_path(ctx, i["name"]),
          _get_runfile_path(ctx, i["image"])
        ) for i in partial_images]
      ),
      "%{tag}": tag,
    },
    output=ctx.outputs.executable,
    executable=True
  )
  _assemble_image(ctx, partial_images)

  runfiles = ctx.runfiles(
    files=[i["name"] for i in partial_images] + [i["image"] for i in partial_images]
  )
  return struct(
    runfiles=runfiles,
    files=set([ctx.outputs.partial]),
    image_config=config,
    partial_images=partial_images,
  )


container_image = rule(
  implementation=_container_image_impl,
  attrs={
    "base": attr.label(single_file=True),
    "layers": attr.label_list(allow_files=layer_filetype),
    "user": attr.string(),
    "entrypoint": attr.string_list(),
    "cmd": attr.string_list(),
    "env": attr.string_dict(),
    "ports": attr.string_list(),  # Skylark doesn't support int_list...
    "volumes": attr.string_list(),
    "workdir": attr.string(),
    "labels": attr.string_dict(),
    "image_name": attr.string(),
    "image_tag": attr.string(),
    "config_file": attr.label(single_file=True, allow_files=True),
    "_create_image_config": attr.label(
      default=Label("//container/oci:image"),
      cfg="host",
      executable=True,
      allow_files=True),
    "_create_image": attr.label(
      default=Label("//container:create_image"),
      cfg="host",
      executable=True,
      allow_files=True),
    "_assemble_image": attr.label(
      default=Label("//container:assemble_image"),
      cfg="host",
      executable=True,
      allow_files=True),
    "_incremental_load_template": attr.label(
      default=Label("//container:docker_incremental_load_template"),
      single_file=True,
      allow_files=True),
    "_sha256": attr.label(
      default=Label("@bazel_tools//tools/build_defs/docker:sha256"),
      cfg="host",
      executable=True,
      allow_files=True)
  },
  outputs={
    "image": "%{name}.tar",
    "partial": "%{name}.partial.tar",
  },
  executable=True
)
"""Creates an image which conforms to the OCI Image Serialization specification.

More information on the specification is available at
https://github.com/opencontainers/image-spec/blob/v0.2.0/serialization.md.

By default this rule builds partial images which can be loaded into a container
runtime via `bazel run`. To build a standalone image build with .tar at the end
if the name. The resulting tarball is compatible with `docker load` and has the
structure:
```
{image-config-sha256}:
  {layer-sha256}.tar
{image-config-sha256}.json
...
manifest.json
```

Args:
  base: The base container image on top of which this image will built upon,
    equivalent to FROM in a Dockerfile.
  layers: List of layers created by `container_layer` that make up this image.
  entrypoint: The entrypoint of the command when the image is run.
  cmd: A command to execute when the image is run.
  ports: List of ports to expose.
  user: The user that the image should run as. Because building the image never
    happens inside a container, this user does not affect the other actions
    (e.g., adding files).
  volumes: List of volumes to mount.
  workdir: Initial working directory when running the container. Because
    building the image never happens inside a container, this working directory
    does not affect the other actions (e.g., adding files).
  env: Dictionary from environment variable names to their values when running
    the container. ```env = { "FOO": "bar", ... }```
  labels: Dictionary from label names to their values.
    ```labels = { "foo": "bar", ... }```
  image_name: The name of the image which is used when it is loaded into a
    container runtime. If not provided it will default to
    `bazel/package_name`.
  image_tag: The tag applied to the image when it is loaded into a container
    runtime. If not provided it will default to `target`.
  config_file: Use an existing container configuration file.

Outputs:
  image: A container image that contains all partial images which can be loaded
    standalone by the container runtime.
  partial: A partial container image that contains no parent images. Used when
    running the rule to only load changed images into the container runtime.

Example:
  ```python
  load("@bazel_rules_container//container:layer.bzl", "container_layer")
  load("@bazel_rules_container//container:image.bzl", "container_image")

  container_layer(
      name = "jessie_layer",
      tars = [":jessie_tar"],
  )
  container_image(
      name = "jessie",
      layers = [":jessie_layer"],
  )

  # Using the `nodejs_files` layer from the `container_layer` example
  container_image(
      name = "nodejs",
      layers = [":nodejs_files"],
  )
  ```
"""
