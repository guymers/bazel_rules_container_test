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
"""Pull out the config and layer sections of a container manifest."""

import json
import sys


def parse_manifest(manifest_file, config_file, layers_file):
  """Extracts the config and layer sections of a container manifest.

  Args:
    manifest_file: the name of the docker image file to create.
    config_file: the identifier for this image (sha256 of the metadata).
    layers_file: the layer content (a sha256 and a tar file).
  """
  with open(manifest_file, 'r') as f:
    manifest_contents = f.read()
  manifest = json.loads(manifest_contents)

  config = manifest['config']['digest']
  with open(config_file, "w") as out:
    out.write(config)

  layers = [l['digest'] for l in manifest['layers']]
  with open(layers_file, "w") as out:
    out.write("\n".join(layers))


def main(argv):
  parse_manifest(argv[1], argv[2], argv[3])

if __name__ == '__main__':
  main(sys.argv)
