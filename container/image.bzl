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
"""Images

Open Container Initiative Image Format support for Bazel

These rules are used for building [OCI images](https://github.com/opencontainers/image-spec).

Each image can contain multiple layers which can be created via the
`container_layer` rule.
"""

load(
  "@bazel_tools//tools/build_defs/hash:hash.bzl",
  _sha256 = "sha256",
)
load(
  "@io_bazel_rules_docker//skylib:zip.bzl",
  _gzip = "gzip",
  _zip_tools = "tools",
)

layer_filetype = [".layer"]


def _create_image_config_file(ctx, layers):
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
    base_image_config = None

    if hasattr(ctx.attr.base, "image_config"):
      base_image_config = getattr(ctx.attr.base, "image_config")

    if not base_image_config:
      # support a docker rule base image
      if hasattr(ctx.attr.base, "container_parts"):
        container_parts = getattr(ctx.attr.base, "container_parts")
        base_image_config = container_parts["config"]

    if base_image_config:
      args += ["--base=%s" % base_image_config.path]
      inputs += [base_image_config]

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
  return ctx.outputs.image

def _assemble_aci_image(ctx, image):
  args = [image.path, ctx.outputs.aci_image.path]
  ctx.action(
    executable=ctx.executable._docker2aci,
    arguments=args,
    inputs=[image],
    outputs=[ctx.outputs.aci_image],
    mnemonic="AssembleAciImage"
  )
  return ctx.outputs.aci_image

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


def _zip_layer(ctx, layer):
  zipped_layer = _gzip(ctx, layer)
  return zipped_layer, _sha256(ctx, zipped_layer)


def _container_image_impl(ctx):
  layers = [getattr(l, "layer") for l in ctx.attr.layers]
  if ctx.file.config_file:
    config_file = ctx.file.config_file
  else:
    config_file = _create_image_config_file(ctx, layers)
  config_digest = _sha256(ctx, config_file)

  tag = _container_image_name(ctx) + ":" + _container_image_tag(ctx)
  _create_partial_image(ctx, config_digest, config_file, layers, [tag])

  partial_images = getattr(ctx.attr.base, "partial_images", []) + [{
    "name": config_digest,
    "image": ctx.outputs.partial
  }]

  # docker rule compatibility
  base = ctx.file.base
  if base:
    parent_parts = getattr(ctx.attr.base, "container_parts")
  else:
    parent_parts = {}

  zipped_layers = [_zip_layer(ctx, l["layer"]) for l in layers]

  container_parts = {
    "config": config_file,
    "config_digest": config_digest,

    "zipped_layer": parent_parts.get("zipped_layer", []) + [l[0] for l in zipped_layers],
    "blobsum": parent_parts.get("blobsum", []) + [l[1] for l in zipped_layers],

    "unzipped_layer": parent_parts.get("unzipped_layer", []) + [l["layer"] for l in layers],
    "diff_id": parent_parts.get("diff_id", []) + [l["name"] for l in layers],
  }

  # Generate the load script
  ctx.template_action(
    template=ctx.file._docker_incremental_load_template,
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
  image = _assemble_image(ctx, partial_images)
  _assemble_aci_image(ctx, image)

  runfiles = ctx.runfiles(
    files=[i["name"] for i in partial_images] + [i["image"] for i in partial_images]
  )
  return struct(
    runfiles=runfiles,
    files=depset([ctx.outputs.partial]),
    image_config=config_file,
    partial_images=partial_images,
    container_parts=container_parts,
  )


container_image = rule(
  doc = """
Creates an image which conforms to the OCI Image Serialization specification.

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
""",
  implementation=_container_image_impl,
  attrs={
    "base": attr.label(
      doc = "The base container image on top of which this image will built upon, equivalent to FROM in a Dockerfile.",
      single_file = True
    ),
    "layers": attr.label_list(
      doc = "List of layers created by `container_layer` that make up this image.",
      allow_files = layer_filetype
    ),
    "user": attr.string(
      doc = "The user that the image should run as. Because building the image never happens inside a container, this user does not affect the other actions (e.g., adding files)."
    ),
    "entrypoint": attr.string_list(
      doc = "The entrypoint of the command when the image is run."
    ),
    "cmd": attr.string_list(
      doc = "A command to execute when the image is run."
    ),
    "env": attr.string_dict(
      doc = """Dictionary from environment variable names to their values when running the container. ```env = { "FOO": "bar", ... }```"""
    ),
    # Skylark doesn't support int_list...
    "ports": attr.string_list(
      doc = "List of ports to expose."
    ),
    "volumes": attr.string_list(
      doc = "List of volumes to mount."
    ),
    "workdir": attr.string(
      doc = "Initial working directory when running the container. Because building the image never happens inside a container, this working directory does not affect the other actions (e.g., adding files)."
    ),
    "labels": attr.string_dict(
      doc = """Dictionary from label names to their values. ```labels = { "foo": "bar", ... }```"""
    ),
    "image_name": attr.string(
      doc = "The name of the image which is used when it is loaded into a container runtime. If not provided it will default to `bazel/package_name`."
    ),
    "image_tag": attr.string(
      doc = "The tag applied to the image when it is loaded into a container runtime. If not provided it will default to `target`."
    ),
    "config_file": attr.label(
      doc = "Use an existing container configuration file.",
      single_file = True,
      allow_files = True
    ),
    "_create_image_config": attr.label(
      default=Label("//container/oci:image"),
      cfg="host",
      executable=True,
      allow_files=True,
    ),
    "_create_image": attr.label(
      default=Label("//container:create_image"),
      cfg="host",
      executable=True,
      allow_files=True,
    ),
    "_assemble_image": attr.label(
      default=Label("//container:assemble_image"),
      cfg="host",
      executable=True,
      allow_files=True,
    ),
    "_docker_incremental_load_template": attr.label(
      default=Label("//container/docker:incremental_load_template"),
      single_file=True,
      allow_files=True
    ),
    "_docker2aci": attr.label(
      default=Label("//container/rkt:docker2aci"),
      cfg="host",
      executable=True,
      allow_files=True,
    ),
    "sha256": attr.label(
      default = Label("@bazel_tools//tools/build_defs/hash:sha256"),
      cfg = "host",
      executable = True,
      allow_files = True,
    ),
    # copy this as skydoc cannot parse `dict({...}.items() + _zip_tools.items())`
    "gzip": attr.label(
      allow_files = True,
      cfg = "host",
      default = Label("@gzip//:gzip"),
      executable = True,
    ),
  },
  outputs={
    "image": "%{name}.tar",
    "aci_image": "%{name}.aci",
    "partial": "%{name}.partial.tar",
  },
  executable=True
)
