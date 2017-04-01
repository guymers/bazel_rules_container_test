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

import sys
import tarfile

from third_party.py import gflags

gflags.DEFINE_string(
    'output', None,
    'The output file, mandatory')
gflags.MarkFlagAsRequired('output')

gflags.DEFINE_string(
    'src', None,
    'The src tar file')
gflags.MarkFlagAsRequired('src')

gflags.DEFINE_multistring(
    'rename', [],
    'Directory to rename to another directory')
gflags.RegisterValidator(
  'rename',
  lambda l: all(value.find(':') > 0 for value in l),
  message='--rename value should contain a : separator')

FLAGS = gflags.FLAGS


def main(unused_argv):
  src = FLAGS.src
  dest = FLAGS.output

  renames = {}
  for rename in FLAGS.rename:
    parts = rename.split(':', 1)
    p1 = parts[0]
    if p1.startswith('/'):
      p1 = '.' + p1

    p2 = parts[1]
    if p2.startswith('/'):
      p2 = '.' + p2

    renames[p1] = p2

  members = {}
  new_names = {}

  source = tarfile.open(fileobj=open(src), mode='r|*')
  for source_member in source:
    name = source_member.name
    for key in renames:
      if name.startswith(key):
        new_names[name] = renames[key] + name[len(key):]
        break
    members[name] = source_member
  source.close()

  # avoid duplicates by not copying renamed files that have the same name
  # as an existing file
  source = tarfile.open(fileobj=open(src), mode='r|*')
  destination = tarfile.open(fileobj=open(dest, 'w'), mode='w|')
  for source_member in source:
    name = source_member.name
    member = members[name]
    add_file = True

    new_name = new_names.get(name, None)
    if new_name:
      if members.get(new_name, None):
        add_file = False
      else:
        member.name = new_name

    if add_file:
      if source_member.isfile():
        destination.addfile(member, source.extractfile(source_member))
      else:
        destination.addfile(member)

  destination.close()
  source.close()


if __name__ == '__main__':
  main(FLAGS(sys.argv))
