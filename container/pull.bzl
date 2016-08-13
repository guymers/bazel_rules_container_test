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

MANIFEST_URL = "/v2/{name}/manifests/{reference}"
BLOB_URL = "/v2/{name}/blobs/{digest}"

def _image_name(repository_ctx):
  image_name = repository_ctx.attr.image_name
  if "/" not in image_name:
    image_name = "library/" + image_name
  return image_name

def _download_blob(repository_ctx, digest, output):
  url = repository_ctx.attr.registry + BLOB_URL.format(
    name=_image_name(repository_ctx),
    digest=digest
  )

  sha256 = digest[7:]
  repository_ctx.download(url, output, sha256)
  return sha256

def _parse_manifest(repository_ctx):
  repository_ctx.file("manifest_config")
  repository_ctx.file("manifest_layers")

  result = repository_ctx.execute([
    "python",
    repository_ctx.path(Label("//container:parse_manifest.py")),
    "%s" % repository_ctx.path("manifest.json"),
    "%s" % repository_ctx.path("manifest_config"),
    "%s" % repository_ctx.path("manifest_layers")
  ])
  return result

def _impl(repository_ctx):
  image_name = _image_name(repository_ctx)
  reference = repository_ctx.attr.image_reference
  manifest_url = repository_ctx.attr.registry + MANIFEST_URL.format(
    name=image_name,
    reference="sha256:" + reference
  )
  repository_ctx.download(manifest_url, "manifest.json", reference)

  result = _parse_manifest(repository_ctx)
  if result.return_code:
    fail("parse manifest failed with error code %s:\n%s" % (result.return_code, result.stderr))

  result = repository_ctx.execute(["cat", repository_ctx.path("manifest_config")])
  if result.return_code:
    fail("manifest config failed with error code %s:\n%s" % (result.return_code, result.stderr))
  config_digest = result.stdout
  _download_blob(repository_ctx, config_digest, "config.json")

  result = repository_ctx.execute(["cat", repository_ctx.path("manifest_layers")])
  if result.return_code:
    fail("manifest layer failed with error code %s:\n%s" % (result.return_code, result.stderr))
  layers = []
  layer_digests = result.stdout.splitlines()
  for layer_digest in layer_digests:
    # TODO use the layer "mediaType": "application/vnd.docker.image.rootfs.diff.tar.gzip"
    layer_file = "layers/" + layer_digest[7:] + ".tar.gz"
    layer = _download_blob(repository_ctx, layer_digest, layer_file)
    layers += [layer]

  repository_ctx.template(
    "BUILD",
    Label("//container:BUILD_PULL.tpl"),
    {
      "%{image_name}": repository_ctx.attr.image_name,
      "%{image_tag}": repository_ctx.attr.image_tag,
      "%{config_file}": "config.json",
      "%{layers}": ", ".join(["\"%s\"" % l for l in layers]),
    }
  )

container_pull = repository_rule(
  implementation = _impl,
  attrs = {
    "registry": attr.string(mandatory=True),
    "image_name": attr.string(mandatory=True),
    "image_tag": attr.string(),
    "image_reference": attr.string(mandatory=True),
  }
)
"""Pulls an image from a container registry.

If you use a registry that requires authentication, set up a local registry
that proxies it by following:
https://blog.docker.com/2015/10/registry-proxy-cache-docker-open-source/

Args:
  registry: The url of the container registry.
  image_name: The name of the image to pull.
  image_tag: The tag of the image, only used for tagging not for pulling.
  image_reference: The sha256 digest of the image.

Outputs:
  image: The container image which can be loaded into a container runtime.

Example:
  ```python
  load("@bazel_rules_container//container:pull.bzl", "container_pull")

  container_pull(
    name = "debian_jessie",
    registry = "http://docker-registry:5000",
    image_name = "debian",
    image_tag = "8.5",
    image_reference = "ffb60fdbc401b2a692eef8d04616fca15905dce259d1499d96521970ed0bec36",
  )
  ```
"""
