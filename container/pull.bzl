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
"""Pull a container from a registry"""

def _sha256(repository_ctx, file):
  result = repository_ctx.execute([
    "sha256sum",
    repository_ctx.path(file),
  ])
  if result.return_code:
    fail("Failed to calculate sha256 of file %s, error code %s:\n%s" % (file, result.return_code, result.stderr))
  return result.stdout.partition()[0]


def _parse_manifest(repository_ctx):
  repository_ctx.file("manifest_config")
  repository_ctx.file("manifest_layers")

  result = repository_ctx.execute([
    "python",
    repository_ctx.path(Label("//container/pull:parse_manifest.py")),
    "%s" % repository_ctx.path("manifest.json"),
    "%s" % repository_ctx.path("manifest_config"),
    "%s" % repository_ctx.path("manifest_layers"),
    ])
  return result


def _impl(repository_ctx):
  skopeo = repository_ctx.path(repository_ctx.attr._skopeo)
  result = repository_ctx.execute([
    skopeo,
    "--policy=%s" % repository_ctx.path(repository_ctx.attr.policy),
    "copy",
    "%s://%s:%s" % (repository_ctx.attr.storage, repository_ctx.attr.image_name, repository_ctx.attr.image_tag),
    "dir:.",
  ])
  if result.return_code:
    fail("Failed to download %s, error code %s:\n%s" % (repository_ctx.attr.image_name, result.return_code, result.stderr))

  manifest_digest = _sha256(repository_ctx, "manifest.json")
  if manifest_digest != repository_ctx.attr.image_reference:
    fail("Manifest does not have digest %s" % repository_ctx.attr.image_reference)

  result = _parse_manifest(repository_ctx)
  if result.return_code:
    fail("parse manifest failed with error code %s:\n%s" % (result.return_code, result.stderr))

  result = repository_ctx.execute(["cat", repository_ctx.path("manifest_config")])
  if result.return_code:
    fail("manifest config failed with error code %s:\n%s" % (result.return_code, result.stderr))
  config_digest = result.stdout[7:]

  result = repository_ctx.execute(["cat", repository_ctx.path("manifest_layers")])
  if result.return_code:
    fail("manifest layer failed with error code %s:\n%s" % (result.return_code, result.stderr))
  layer_digests = [l[7:] for l in result.stdout.splitlines()]

  repository_ctx.template(
    "BUILD",
    Label("//container/pull:BUILD_PULL.tpl"),
    {
      "%{image_name}": repository_ctx.attr.image_name,
      "%{image_tag}": repository_ctx.attr.image_tag,
      "%{config_file}": config_digest + ".tar",
      "%{layers}": ", ".join(["\"%s\"" % l for l in layer_digests]),
      "%{layer_extension}": "tar",
    }
  )

container_pull = repository_rule(
  implementation = _impl,
  attrs = {
    "image_name": attr.string(mandatory=True),
    "image_tag": attr.string(mandatory=True),
    "image_reference": attr.string(mandatory=True),
    "storage": attr.string(default="docker"),
    "policy": attr.label(
      default = Label("@skopeo//:default-policy.json"),
      allow_files = True,
      single_file = True,
      cfg = "host",
    ),
    "_skopeo": attr.label(
      # default = Label("@skopeo//cmd/skopeo"),
      default = Label("@skopeo//dist:skopeo"),
      executable = True,
      cfg = "host",
    ),
  }
)
"""Pulls an image from a container registry.

If you use a registry that requires authentication, see
https://github.com/projectatomic/skopeo

Args:
  image_name: The name of the image to pull.
  image_tag: The tag of the image to pull.
  image_reference: The sha256 digest of the image.
  storage: Where to pull the image from; see https://github.com/projectatomic/skopeo
  policy: See https://github.com/containers/image/blob/master/docs/policy.json.md

Outputs:
  image: The container image which can be loaded into a container runtime.

Example:
  ```python
  load("@bazel_rules_container//container:pull.bzl", "container_pull")

  container_pull(
    name = "debian_jessie",
    image_name = "debian",
    image_tag = "8.5",
    image_reference = "2340a704d1f8f9ecb51c24d9cbce9f5ecd301b6b8ea1ca5eaba9edee46a2436d",
  )
  ```
"""
