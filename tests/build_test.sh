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

readonly PLATFORM="$(uname -s | tr 'A-Z' 'a-z')"
if [ "${PLATFORM}" = "darwin" ]; then
  readonly MAGIC_TIMESTAMP="$(date -r 0 "+%b %e  %Y")"
else
  readonly MAGIC_TIMESTAMP="$(date --date=@0 "+%F %R")"
fi

function EXPECT_NO_CONTAINS() {
  local complete="${1}"
  local substring="${2}"
  local message="${3:-Expected '${substring}' to not be in '${complete}'}"

  if echo "${complete}" | grep -Fsq -- "${substring}"; then
    fail "$message"
  fi
}

function check_no_property() {
  local property="${1}"
  local tarball="${2}"
  local image="${3}"
  local test_data="${TEST_DATA_DIR}/${tarball}.tar"

  local config="$(tar xOf "${test_data}" "./${image}.json")"

  # This would be much more accurate if we had 'jq' everywhere.
  EXPECT_NO_CONTAINS "${config}" "\"${property}\":"
}

function EXPECT_CONTAINS() {
  local complete="${1}"
  local substring="${2}"
  local message="${3:-Expected '${substring}' not found in '${complete}'}"

  echo "${complete}" | grep -Fsq -- "${substring}" \
    || fail "$message"
}

function check_property() {
  local property="${1}"
  local tarball="${2}"
  local image="${3}"
  local expected="${4}"
  local test_data="${TEST_DATA_DIR}/${tarball}.tar"

  local config="$(tar xOf "${test_data}" "./${image}.json")"

  # This would be much more accurate if we had 'jq' everywhere.
  EXPECT_CONTAINS "${config}" "\"${property}\":${expected}"
}

function check_entrypoint() {
  input="$1"
  shift
  check_property Entrypoint "${input}" "${@}"
}

function check_cmd() {
  input="$1"
  shift
  check_property Cmd "${input}" "${@}"
}

function check_ports() {
  input="$1"
  shift
  check_property ExposedPorts "${input}" "${@}"
}

function check_volumes() {
  input="$1"
  shift
  check_property Volumes "${input}" "${@}"
}

function check_env() {
  input="$1"
  shift
  check_property Env "${input}" "${@}"
}

function check_workdir() {
  input="$1"
  shift
  check_property WorkingDir "${input}" "${@}"
}

function check_user() {
  input="$1"
  shift
  check_property User "${input}" "${@}"
}

function check_images() {
  local input="$1"
  shift 1
  local expected_images=(${*})
  local test_data="${TEST_DATA_DIR}/${input}.tar"

  local manifest="$(tar xOf "${test_data}" "./manifest.json")"
  local manifest_images=(
    $(echo "${manifest}" | grep -Eo '"Config":[[:space:]]*"[^"]+"' \
      | sed -r -e 's#"Config":.*?"([0-9a-f]+)\.json"#\1#'))

  local manifest_parents=(
    $(echo "${manifest}" | grep -Eo '"Parent":[[:space:]]*"[^"]+"' \
      | sed -r -e 's#"Parent":.*?"sha256:([0-9a-f]+)"#\1#'))

  # Verbose output for testing.
  echo Expected: "${expected_images[@]}"
  echo Actual: "${manifest_images[@]}"
  echo Parents: "${manifest_parents[@]}"

  check_eq "${#expected_images[@]}" "${#manifest_images[@]}"

  local index=0
  while [ "${index}" -lt "${#expected_images[@]}" ]
  do
    # Check that the nth sorted layer matches
    check_eq "${expected_images[$index]}" "${manifest_images[$index]}"

    index=$((index + 1))
  done

  # Check that the image contains its predecessor as its parent in the manifest.
  check_eq "${#manifest_parents[@]}" "$((${#manifest_images[@]} - 1))"

  local index=0
  while [ "${index}" -lt "${#manifest_parents[@]}" ]
  do
    # Check that the nth sorted layer matches
    check_eq "${manifest_parents[$index]}" "${manifest_images[$index]}"

    index=$((index + 1))
  done
}

# The bottom manifest entry must contain all layers in order
function check_image_manifest_layers() {
  local input="$1"
  shift 1
  local expected_layers=(${*})
  local test_data="${TEST_DATA_DIR}/${input}.tar"

  local manifest="$(tar xOf "${test_data}" "./manifest.json")"
  local manifest_layers=(
    $(echo "${manifest}" | grep -Eo '"Layers":[[:space:]]*\[[^]]+\]' \
      | grep -Eo '\[.+\]' | tail -n 1 | tr ',' '\n' \
      | sed -r -e 's#.*".+/([0-9a-f]+)\.tar".*#\1#'))

  # Verbose output for testing.
  echo Expected: "${expected_layers[@]}"
  echo Actual: "${manifest_layers[@]}"

  check_eq "${#expected_layers[@]}" "${#manifest_layers[@]}"

  local index=0
  while [ "${index}" -lt "${#expected_layers[@]}" ]
  do
    # Check that the nth sorted layer matches
    check_eq "${expected_layers[$index]}" "${manifest_layers[$index]}"

    index=$((index + 1))
  done
}

function find_element() {
  local e
  for e in "${@:2}"; do
    if [[ "$e" == *"$1" ]]; then
      echo "$e"
      return 0
    fi
  done
  return 1
}

function find_layer_files() {
  local test_data="$1"
  tar tvf "${test_data}" | grep -E '\.tar$' | tr -s ' ' \
      | cut -d' ' -f 6- | sed 's#^..##' | sort
}

function find_layer_tars() {
  local actual_layer_files=("$@")
  for i in "${actual_layer_files[@]}"; do
    echo "$i" | sed -r -e 's#.*/([0-9a-f]+)\.tar$#\1#'
  done | sort
}

function check_layers_aux() {
  local input="$1"
  shift 1
  local expected_layers=(${*})

  local expected_layers_sorted=(
    $(for i in ${expected_layers[*]}; do echo $i; done | sort)
  )
  local test_data="${TEST_DATA_DIR}/${input}.tar"

  # Verbose output for testing.
  tar tvf "${test_data}"

  local actual_layer_files=($(find_layer_files "$test_data"))
  local actual_layers=($(find_layer_tars "${actual_layer_files[@]}"))

  # Verbose output for testing.
  echo Expected: "${expected_layers_sorted[@]}"
  echo Actual: "${actual_layers[@]}"

  check_eq "${#expected_layers[@]}" "${#actual_layers[@]}"

  local index=0
  while [ "${index}" -lt "${#expected_layers[@]}" ]
  do
    # Check that the nth sorted layer matches
    check_eq "${expected_layers_sorted[$index]}" "${actual_layers[$index]}"

    # Grab the ordered layer and check it.
    local layer_hash="${expected_layers[$index]}"
    local layer="$(find_element "${layer_hash}.tar" "${actual_layer_files[@]}")"

    # Verbose output for testing.
    echo Checking layer: "${layer}"

    local listing="$(tar xOf "${test_data}" "./${layer}" | tar tv)"

    # Check that all files in the layer, if any, have the magic timestamp
    check_eq "$(echo "${listing}" | grep -Fv "${MAGIC_TIMESTAMP}" || true)" ""

    index=$((index + 1))
  done
}

function check_layers() {
  local input="$1"
  shift
  check_layers_aux "$input" "$@"
  check_image_manifest_layers "$input" "$@"
}

function test_gen_image() {
  grep -Fsq "./gen.out" "$TEST_DATA_DIR/gen_image.tar" \
    || fail "'./gen.out' not found in '$TEST_DATA_DIR/gen_image.tar'"
}

function test_dummy_image_info() {
  local layer="684990b8fa36e8a3ce2e6159673a3545e4b1d9d81fb6c9ef2e35ad1d09a6b066"
  local test_data="${TEST_DATA_DIR}/dummy_image_info.tar"
  check_layers_aux "dummy_image_info" "$layer"

  local manifest="$(tar xOf "${test_data}" "./manifest.json")"

  # This would really need to use `jq` instead.
  echo "${manifest}" | \
    grep -Esq -- '"RepoTags":[[:space:]]*\["repo/dummy:9000"\]' \
    || fail "Cannot find tag dummy_repository in image manifest in '${manifest}'"
}

function test_files_base() {
  check_layers "files_base" \
    "a46a4b0b5e99d26f570f3c6668e2b2be57b8bb8efcd78a87597ec19cbc38d8d4"
}

function test_files_with_files_base() {
  check_layers "files_with_files_base" \
    "a46a4b0b5e99d26f570f3c6668e2b2be57b8bb8efcd78a87597ec19cbc38d8d4" \
    "6c47315387439557c38c7802ace18f31a528a4667047126b1b54fd1a292011b7"
}

function test_tar_base() {
  check_layers "tar_base" \
    "70f299789c2a535f64086d83e997e4d7996a0c4089131046de62c1c1a6878563"

  check_no_property "Entrypoint" \
    "tar_base" \
    "f0d32fa758db40fd3a993a2733783cf3d10e2f938e5e777865a8f12d17d9b715"
}

function test_tar_with_tar_base() {
  check_layers "tar_with_tar_base" \
    "70f299789c2a535f64086d83e997e4d7996a0c4089131046de62c1c1a6878563" \
    "efd11a18c1ec4dcaa420b1a0588d199c25d4c85f40e5e016895142f9e5a1b530"
}

function test_directory_with_tar_base() {
  check_layers "directory_with_tar_base" \
    "70f299789c2a535f64086d83e997e4d7996a0c4089131046de62c1c1a6878563" \
    "a22171fbda6f1be28367901534fafd5684539b0c16f79a1fc8355c23c4dc4910"
}

function test_files_with_tar_base() {
  check_layers "files_with_tar_base" \
    "70f299789c2a535f64086d83e997e4d7996a0c4089131046de62c1c1a6878563" \
    "6c47315387439557c38c7802ace18f31a528a4667047126b1b54fd1a292011b7"
}

function test_workdir_with_tar_base() {
  check_layers "workdir_with_tar_base" \
    "70f299789c2a535f64086d83e997e4d7996a0c4089131046de62c1c1a6878563"

  check_workdir "workdir_with_tar_base" \
    "3df43f77b3e4810a5821296cb4f45cc29fc53f6a120e6a5a8390d94decd5ae39" \
    '"/tmp"'
}

function test_tar_with_files_base() {
  check_layers "tar_with_files_base" \
    "a46a4b0b5e99d26f570f3c6668e2b2be57b8bb8efcd78a87597ec19cbc38d8d4" \
    "efd11a18c1ec4dcaa420b1a0588d199c25d4c85f40e5e016895142f9e5a1b530"
}

function test_base_with_entrypoint() {
  check_layers "base_with_entrypoint" \
    "7a3e195bc3f539f343119d6399c3663680bddd86ed2b67e786d7e079602d0afe"

  check_entrypoint "base_with_entrypoint" \
    "0cf275e3818e6f489a119160b988e078ecdafcfd4cb32f8c5fb941c0f106e375" \
    '["/bar"]'

  # Check that the base layer has a port exposed.
  check_ports "base_with_entrypoint" \
    "0cf275e3818e6f489a119160b988e078ecdafcfd4cb32f8c5fb941c0f106e375" \
    '{"8080/tcp":{}}'
}

function test_derivative_with_shadowed_cmd() {
  check_layers "derivative_with_shadowed_cmd" \
    "7a3e195bc3f539f343119d6399c3663680bddd86ed2b67e786d7e079602d0afe" \
    "a46a4b0b5e99d26f570f3c6668e2b2be57b8bb8efcd78a87597ec19cbc38d8d4"

  check_cmd "derivative_with_shadowed_cmd" \
    "d8b92dc6ad627b4455010201271d70d92ca17064af45f3b1f2a31aebe55234cb" \
    '["shadowed-arg"]'
}

function test_derivative_with_cmd() {
  check_layers "derivative_with_cmd" \
    "7a3e195bc3f539f343119d6399c3663680bddd86ed2b67e786d7e079602d0afe" \
    "a46a4b0b5e99d26f570f3c6668e2b2be57b8bb8efcd78a87597ec19cbc38d8d4" \
    "70f299789c2a535f64086d83e997e4d7996a0c4089131046de62c1c1a6878563"

  check_images "derivative_with_cmd" \
    "0cf275e3818e6f489a119160b988e078ecdafcfd4cb32f8c5fb941c0f106e375" \
    "d8b92dc6ad627b4455010201271d70d92ca17064af45f3b1f2a31aebe55234cb" \
    "1c71833f567e7e2803db43009fea93acdabe34431bb747599e15e0ca5d39746a"

  check_entrypoint "derivative_with_cmd" \
    "0cf275e3818e6f489a119160b988e078ecdafcfd4cb32f8c5fb941c0f106e375" \
    '["/bar"]'

  # Check that the middle image has our shadowed arg.
  check_cmd "derivative_with_cmd" \
    "d8b92dc6ad627b4455010201271d70d92ca17064af45f3b1f2a31aebe55234cb" \
    '["shadowed-arg"]'

  # Check that our topmost image excludes the shadowed arg.
  check_cmd "derivative_with_cmd" \
    "1c71833f567e7e2803db43009fea93acdabe34431bb747599e15e0ca5d39746a" \
    '["arg1","arg2"]'

  # Check that the topmost layer has the ports exposed by the bottom
  # layer, and itself.
  check_ports "derivative_with_cmd" \
    "1c71833f567e7e2803db43009fea93acdabe34431bb747599e15e0ca5d39746a" \
    '{"80/tcp":{},"8080/tcp":{}}'
}

function test_derivative_with_volume() {
  check_layers "derivative_with_volume" \
    "2e79ed5944783867c78cb6870d8b8bb7e68857cbc0894d79119d786d93bc09f7"

  check_images "derivative_with_volume" \
    "38830a7291e1a73afdc2904d29840047bdeb19c6640a2ac80dd566e187e6f1d9" \
    "94f4ebc1ee27909c17ba9b6fad0895a1d00fe83bcb08c305501735722be4ac6e"

  # Check that the topmost layer has the ports exposed by the bottom
  # layer, and itself.
  check_volumes "derivative_with_volume" \
    "38830a7291e1a73afdc2904d29840047bdeb19c6640a2ac80dd566e187e6f1d9" \
    '{"/logs":{}}'

  check_volumes "derivative_with_volume" \
    "94f4ebc1ee27909c17ba9b6fad0895a1d00fe83bcb08c305501735722be4ac6e" \
    '{"/asdf":{},"/blah":{},"/logs":{}}'
}

function test_generated_tarball() {
  check_layers "generated_tarball" \
    "4253dd4263db64f09f024ae5a612edc058a12357900c89856cc93888151d79a2"
}

function test_with_env() {
  check_layers "with_env" \
    "2e79ed5944783867c78cb6870d8b8bb7e68857cbc0894d79119d786d93bc09f7"

  check_env "with_env" \
    "410e8dca8b98dd7af8a3f93a5a0cc47333661c250163047f32295cb8c931e571" \
    '["bar=blah blah blah","foo=/asdf"]'
}

function test_with_double_env() {
  check_layers "with_double_env" \
    "2e79ed5944783867c78cb6870d8b8bb7e68857cbc0894d79119d786d93bc09f7"

  # Check both the aggregation and the expansion of embedded variables.
  check_env "with_double_env" \
    "8d16396139bcfdd6cb724243395ae3c3fb1c354bc0ddea336fdf0406f8325273" \
    '["bar=blah blah blah","baz=/asdf blah blah blah","foo=/asdf"]'
}

function test_with_user() {
  check_user "with_user" \
    "96954ffdcaff510c6959f20c24babb18e439e80c3de70b6b2a23216b5bc82938" \
    '"nobody"'
}

function test_layer_from_tar() {
  local test_data="${TEST_DATA_DIR}/layer_from_tar.tar"
  local actual_layer_files=($(find_layer_files "$test_data"))
  local actual_layers=($(find_layer_tars "${actual_layer_files[@]}"))

  local one_tar_sha256=9be445de26620fa800e8affe5ac10366c5763cc08fc26e776252d20a6ed97c77
  check_eq "bc5e5f7b8d20e25a24bd06c9a1536d1266e8b44c6715ab79675bdfebd82d67d9/${one_tar_sha256}.tar" "${actual_layer_files[@]}"
  check_eq "${one_tar_sha256}" "${actual_layers[@]}"
}

function get_layer_listing() {
  local input=$1
  local image=$2
  local layer=$3
  local test_data="${TEST_DATA_DIR}/${input}.tar"
  tar xOf "${test_data}" \
    "./${image}/${layer}.tar" | tar tv | sed -e 's/^.*:00 //'
}

function test_data_path() {
  local no_data_path_image="13d35b5cb60674cb7a233890b1c8744d0982edb961972704dccfdd5936c12a89"
  local no_data_path_layer="73611719e3ca0594496c33bcefbceb13953382726c6573ed7ad65ee27ee3dbb7"
  local data_path_image="bc540a0f1b5dc422a2f83348a792b2bec7990f4affd19f2f39686336a10fb188"
  local data_path_layer="14e748c0c057c22c8a5bbe5552db245b0ee9dfd22ec6ab8bc2e78a38a66232bf"
  local absolute_data_path_image="652124dc22037cd803ffe7da7d17605715cf0ee2a00c11aa9ecfec63cd176c66"
  local absolute_data_path_layer="678598ee367a059eb5d4ac6f04c2d3c8aa9edd6411e49f8db9fe48a79d500299"
  local root_data_path_image="7a4c4b09969642872074b945fca7f66588381de18e624c6327b45fe6df70da8a"
  local root_data_path_layer="a89b6fd942f3cacbd0de607a4b975ab8af5d2a782632cadddf4fcd57e4b3ca58"

  check_layers_aux "no_data_path_image" "${no_data_path_layer}"
  check_layers_aux "data_path_image" "${data_path_layer}"
  check_layers_aux "absolute_data_path_image" "${absolute_data_path_layer}"
  check_layers_aux "root_data_path_image" "${root_data_path_layer}"

  # Without data_path = "." the file will be inserted as `./test`
  # (since it is the path in the package) and with data_path = "."
  # the file will be inserted relatively to the testdata package
  # (so `./test/test`).
  check_eq "$(get_layer_listing "no_data_path_image" "${no_data_path_image}" "${no_data_path_layer}")" \
    './
./test'
  check_eq "$(get_layer_listing "data_path_image" "${data_path_image}" "${data_path_layer}")" \
    './
./test/
./test/test'

  # With an absolute path for data_path, we should strip that prefix
  # from the files' paths. Since the test data images are in
  # //tests/data and data_path is set to "/tests", we should
  # have `data` as the top-level directory.
  check_eq "$(get_layer_listing "absolute_data_path_image" "${absolute_data_path_image}" "${absolute_data_path_layer}")" \
    './
./data/
./data/test/
./data/test/test'

  # With data_path = "/", we expect the entire path from the repository
  # root.
  check_eq "$(get_layer_listing "root_data_path_image" "${root_data_path_image}" "${root_data_path_layer}")" \
    "./
./tests/
./tests/data/
./tests/data/test/
./tests/data/test/test"
}

function test_extras_with_deb() {
  local test_data="${TEST_DATA_DIR}/extras_with_deb.tar"
  local image="4289fd6d4c326c15d5e232488094bacb0bd5c9284074b3206a616665e4ab8e94"
  local layer="6b372b366b95cf9f94f1245cfc0852f3fe9efa5dd6b7924822c15d2a3019511e"

  # The content of the layer should have no duplicate
  local layer_listing="$(get_layer_listing "extras_with_deb" "${image}" "${layer}" | sort)"
  check_eq "${layer_listing}" \
"./
./etc/
./etc/nsswitch.conf
./tmp/
./usr/
./usr/bin/
./usr/bin/java -> /path/to/bin/java
./usr/titi"
}

run_suite "build_test"
