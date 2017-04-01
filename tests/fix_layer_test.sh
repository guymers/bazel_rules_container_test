#!/bin/bash

# Copyright 2016 The Bazel Authors. All rights reserved.
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

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$DIR/testenv.sh" || { echo "testenv.sh not found!" >&2; exit 1; }

function layer_contents_list() {
  local tar_name="$1"
  local tar_file="${TEST_DATA_DIR}/${tar_name}.layer"
  tar --list -f "${tar_file}" | sort
}

function layer_file_contents() {
  local tar_name="$1"
  local file_name="$2"
  local tar_file="${TEST_DATA_DIR}/${tar_name}.layer"
  tar --extract -O -f "${tar_file}" "${file_name}"
}

function test_prog() {

  local file_list="$(layer_contents_list "prog_layer")"
  check_eq "${file_list}" \
"./
./bin/
./bin/prog
./lib/
./lib/libprog.so
./usr/
./usr/share/
./usr/share/prog"

  local file_list="$(layer_contents_list "prog_layer_fix")"
  check_eq "${file_list}" \
"./
./usr/
./usr/bin/
./usr/bin/prog
./usr/lib/
./usr/lib/libprog.so
./usr/share/
./usr/share/prog"
}

function test_prog_duplicate() {

  local file_list="$(layer_contents_list "prog_duplicate_layer")"
  check_eq "${file_list}" \
"./
./bin/
./bin/prog
./lib/
./lib/libprog.so
./usr/
./usr/bin/
./usr/bin/prog
./usr/share/
./usr/share/prog"

  local file_list="$(layer_contents_list "prog_duplicate_layer_fix")"
  check_eq "${file_list}" \
"./
./usr/
./usr/bin/
./usr/bin/prog
./usr/lib/
./usr/lib/libprog.so
./usr/share/
./usr/share/prog"

  local prog_contents="$(layer_file_contents "prog_duplicate_layer_fix" "./usr/bin/prog")"
  check_eq "${prog_contents}" "prog"
}

function test_prog_no_renames() {

  local file_list="$(layer_contents_list "prog_no_renames_layer")"
  check_eq "${file_list}" \
"./
./usr/
./usr/bin/
./usr/bin/prog
./usr/lib/
./usr/lib/libprog.so
./usr/share/
./usr/share/prog"

  local file_list="$(layer_contents_list "prog_no_renames_layer_fix")"
  check_eq "${file_list}" \
"./
./usr/
./usr/bin/
./usr/bin/prog
./usr/lib/
./usr/lib/libprog.so
./usr/share/
./usr/share/prog"
}

run_suite "fix_layer_test"
