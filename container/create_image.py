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
"""This tool creates a docker image from a layer and the various metadata."""

import json
import re
import sys

from container import utils
from bazel.tools.build_defs.pkg import archive
from third_party.py import gflags

# Hardcoded docker versions that we are claiming to be.
DATA_FORMAT_VERSION = '1.0'

gflags.DEFINE_string(
    'output', None,
    'The output file, mandatory')
gflags.MarkFlagAsRequired('output')

gflags.DEFINE_multistring(
    'layer', [],
    'Layer tar files and their identifiers that make up this image')

gflags.DEFINE_string(
    'id', None,
    'The hex identifier of this image (hexstring or @filename), mandatory.')
gflags.MarkFlagAsRequired('id')

gflags.DEFINE_string('config', None,
                     'The JSON configuration file for this image, mandatory.')
gflags.MarkFlagAsRequired('config')

gflags.DEFINE_string('base', None, 'The base image file for this image.')

gflags.DEFINE_multistring('tag', None,
                          'The repository tags to apply to the image')

FLAGS = gflags.FLAGS


def create_image(output,
                 identifier,
                 layers,
                 config,
                 tags=None,
                 base=None):
  """Creates a container image.

  Args:
    output: the name of the docker image file to create.
    identifier: the identifier for this image (sha256 of the metadata).
    layers: the layer content (a sha256 and a tar file).
    config: the configuration file for the image.
    tags: tags that apply to this image.
    base: a base layer (optional) to build on top of.
  """
  tar = archive.TarFileWriter(output)

  # add the image config referenced by the Config section in the manifest
  # the name can be anything but docker uses the format below
  config_file_name = identifier + '.json'
  tar.add_file(config_file_name, file_content=config)

  layer_file_names = []

  for layer in layers:
    # layers can be called anything, so just name them by their sha256
    layer_file_name = identifier + '/' + layer['name'] + '.tar'
    layer_file_names.append(layer_file_name)
    tar.add_file(layer_file_name, file_content=layer['layer'])

  base_layer_file_names = []
  parent = None
  if base:
    latest_item = utils.GetLatestManifestFromTar(base)
    if latest_item:
      base_layer_file_names = latest_item.get('Layers', [])
      config_file = latest_item['Config']
      parent_search = re.search('^(.+)\\.json$', config_file)
      if parent_search:
        parent = parent_search.group(1)

  manifest_item = {
      'Config': config_file_name,
      'Layers': base_layer_file_names + layer_file_names,
      'RepoTags': tags or []
  }
  if parent:
    manifest_item['Parent'] = 'sha256:' + parent

  manifest = [manifest_item]

  manifest_content = json.dumps(manifest, sort_keys=True)
  tar.add_file('manifest.json', content=manifest_content)


# Main program to create a container image. It expect to be run with:
# create_image --output=output_file \
#              --id=@identifier \
#              [--base=base] \
#              --layer=@identifier=layer.tar \
#              --tag=repo/image:tag
# See the gflags declaration about the flags argument details.
def main(unused_argv):
  identifier = utils.ExtractValue(FLAGS.id)

  layers = []
  for kv in FLAGS.layer:
    (k, v) = kv.split('=', 1)
    layers.append({
        'name': utils.ExtractValue(k),
        'layer': v,
    })

  create_image(FLAGS.output, identifier, layers, FLAGS.config, FLAGS.tag,
               FLAGS.base)

if __name__ == '__main__':
  main(FLAGS(sys.argv))
