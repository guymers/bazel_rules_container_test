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
"""This tool creates a container image from a list of partial images."""
# This is the main program to create a container image. It expect to be run with:
# assemble_image --output=output_file \
#                --image=image1 [--image=image2 ... --image=imageN] \
# See the gflags declaration about the flags argument details.

import json
import os.path
import sys

from bazel.tools.build_defs.pkg import archive
from third_party.py import gflags
from utils import GetManifestFromTar

gflags.DEFINE_string('output', None, 'The output file, mandatory')
gflags.MarkFlagAsRequired('output')

gflags.DEFINE_multistring('image', [], 'The partial image tar files to merge.')

FLAGS = gflags.FLAGS


def _image_filter(name):
  """Ignore any 'manifest.json' files when merging images."""
  basename = os.path.basename(name)
  return basename != 'manifest.json'


def assemble_image(output, images):
  """Creates a container image from a list of partial images.

  Merges all manifests from each image and combine the image tars.

  Args:
    output: the name of the container image file to create.
    images: the images (tar files) to join together.
  """
  manifest = []

  tar = archive.TarFileWriter(output)
  for image in images:
    tar.add_tar(image, name_filter=_image_filter)
    manifest += GetManifestFromTar(image)

  manifest_content = json.dumps(manifest, sort_keys=True)
  tar.add_file('manifest.json', content=manifest_content)


def main(unused_argv):
  assemble_image(FLAGS.output, FLAGS.image)


if __name__ == '__main__':
  main(FLAGS(sys.argv))
