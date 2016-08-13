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

# Unit tests for docker_build

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source ${DIR}/testenv.sh || { echo "testenv.sh not found!" >&2; exit 1; }

readonly PLATFORM="$(uname -s | tr 'A-Z' 'a-z')"
if [ "${PLATFORM}" = "darwin" ]; then
  readonly MAGIC_TIMESTAMP="$(date -r 0 "+%b %e  %Y")"
else
  readonly MAGIC_TIMESTAMP="$(date --date=@0 "+%F %R")"
fi

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
  EXPECT_CONTAINS "${config}" "\"${property}\": ${expected}"
}

function check_no_property() {
  local property="${1}"
  local tarball="${2}"
  local image="${3}"
  local test_data="${TEST_DATA_DIR}/${tarball}.tar"

  tar xOf "${test_data}" "./${image}.json" >$TEST_log
  expect_not_log "\"${property}\":"
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

  # Check that this layer doesn't have any entrypoint data by looking
  # for *any* entrypoint.
  check_no_property "Entrypoint" "tar_base" \
    "9fec194fd32c03350d6a6e60ee8ed7862471e8817aaa310306d9be6242b05d20"
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
    "7ea871b00be8b444b3a0008e71a55c18d674f3380593d1c301809823cf59cfd7" \
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
    "d59ab78d94f88b906227b8696d3065b91c71a1c6045d5103f3572c1e6fe9a1a9" \
    '["/bar"]'

  # Check that the base layer has a port exposed.
  check_ports "base_with_entrypoint" \
    "d59ab78d94f88b906227b8696d3065b91c71a1c6045d5103f3572c1e6fe9a1a9" \
    '{"8080/tcp": {}}'
}

function test_derivative_with_shadowed_cmd() {
  check_layers "derivative_with_shadowed_cmd" \
    "7a3e195bc3f539f343119d6399c3663680bddd86ed2b67e786d7e079602d0afe" \
    "a46a4b0b5e99d26f570f3c6668e2b2be57b8bb8efcd78a87597ec19cbc38d8d4"

  check_cmd "derivative_with_shadowed_cmd" \
    "a37fcc5dfa513987ecec8a19ebe5d17568a7d6e696771c596b110fcc30a2d8a6" \
    '["shadowed-arg"]'
}

function test_derivative_with_cmd() {
  check_layers "derivative_with_cmd" \
    "7a3e195bc3f539f343119d6399c3663680bddd86ed2b67e786d7e079602d0afe" \
    "a46a4b0b5e99d26f570f3c6668e2b2be57b8bb8efcd78a87597ec19cbc38d8d4" \
    "70f299789c2a535f64086d83e997e4d7996a0c4089131046de62c1c1a6878563"

  check_images "derivative_with_cmd" \
    "d59ab78d94f88b906227b8696d3065b91c71a1c6045d5103f3572c1e6fe9a1a9" \
    "a37fcc5dfa513987ecec8a19ebe5d17568a7d6e696771c596b110fcc30a2d8a6" \
    "d3ea6e7cfc3e182a8ca43081db1e145f1bee8c5da5627639800c76abf61b5165"

  check_entrypoint "derivative_with_cmd" \
    "d59ab78d94f88b906227b8696d3065b91c71a1c6045d5103f3572c1e6fe9a1a9" \
    '["/bar"]'

  # Check that the middle image has our shadowed arg.
  check_cmd "derivative_with_cmd" \
    "a37fcc5dfa513987ecec8a19ebe5d17568a7d6e696771c596b110fcc30a2d8a6" \
    '["shadowed-arg"]'

  # Check that our topmost image excludes the shadowed arg.
  check_cmd "derivative_with_cmd" \
    "d3ea6e7cfc3e182a8ca43081db1e145f1bee8c5da5627639800c76abf61b5165" \
    '["arg1", "arg2"]'

  # Check that the topmost layer has the ports exposed by the bottom
  # layer, and itself.
  check_ports "derivative_with_cmd" \
    "d3ea6e7cfc3e182a8ca43081db1e145f1bee8c5da5627639800c76abf61b5165" \
    '{"80/tcp": {}, "8080/tcp": {}}'
}

function test_derivative_with_volume() {
  check_layers "derivative_with_volume" \
    "2e79ed5944783867c78cb6870d8b8bb7e68857cbc0894d79119d786d93bc09f7"

  check_images "derivative_with_volume" \
    "da0f0e314eb3187877754fd5ee1e487b93c13dbabdba18f35d130324f3c9b76d" \
    "fec394d786d21e2abfc1da8ccd09c89c9348ab6c0480af8e723269df84933a0b"

  # Check that the topmost layer has the ports exposed by the bottom
  # layer, and itself.
  check_volumes "derivative_with_volume" \
    "da0f0e314eb3187877754fd5ee1e487b93c13dbabdba18f35d130324f3c9b76d" \
    '{"/logs": {}}'

  check_volumes "derivative_with_volume" \
    "fec394d786d21e2abfc1da8ccd09c89c9348ab6c0480af8e723269df84933a0b" \
    '{"/asdf": {}, "/blah": {}, "/logs": {}}'
}

function test_generated_tarball() {
  check_layers "generated_tarball" \
    "4253dd4263db64f09f024ae5a612edc058a12357900c89856cc93888151d79a2"
}

function test_with_env() {
  check_layers "with_env" \
    "2e79ed5944783867c78cb6870d8b8bb7e68857cbc0894d79119d786d93bc09f7"

  check_env "with_env" \
    "0b485917d2cc4294a2b79080e8cfae6d7f0f832e5f814ca75e59249f806e8d05" \
    '["bar=blah blah blah", "foo=/asdf"]'
}

function test_with_double_env() {
  check_layers "with_double_env" \
    "2e79ed5944783867c78cb6870d8b8bb7e68857cbc0894d79119d786d93bc09f7"

  # Check both the aggregation and the expansion of embedded variables.
  check_env "with_double_env" \
    "9736c3eecd9c7e8e29198a89c3f12451ba5f8b5dd605c28c57f01d65ef5f938e" \
    '["bar=blah blah blah", "baz=/asdf blah blah blah", "foo=/asdf"]'
}

function test_with_user() {
  check_user "with_user" \
    "fa96bb0372fad4eb193faf5a0491d819c5567eda694527f2ea001a6bf87a59c1" \
    '"nobody"'
}

function test_layer_from_tar() {
  local test_data="${TEST_DATA_DIR}/layer_from_tar.tar"
  local actual_layer_files=($(find_layer_files "$test_data"))
  local actual_layers=($(find_layer_tars "${actual_layer_files[@]}"))

  local one_tar_sha256=9be445de26620fa800e8affe5ac10366c5763cc08fc26e776252d20a6ed97c77
  check_eq "0fc1d1773b5710f57d46957347747e6b9dfaea1a82ca6460ae65966d69dc65a0/${one_tar_sha256}.tar" "${actual_layer_files[@]}"
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
  local no_data_path_image="0b7d7513d9a8c603ceeabe33423299bd5d3012fde0065ffef00404b3b0ffee0c"
  local no_data_path_layer="73611719e3ca0594496c33bcefbceb13953382726c6573ed7ad65ee27ee3dbb7"
  local data_path_image="8afbaf96650945d6fd485a221bbf7b264eda70bda64cd176f91ccb2912789ad2"
  local data_path_layer="14e748c0c057c22c8a5bbe5552db245b0ee9dfd22ec6ab8bc2e78a38a66232bf"
  local absolute_data_path_image="ccbc2ad599fd6076902a5ae6c3081deff3c866ee0223e9c359ffa2bae09ae482"
  local absolute_data_path_layer="678598ee367a059eb5d4ac6f04c2d3c8aa9edd6411e49f8db9fe48a79d500299"
  local root_data_path_image="5cbbb39e1f696207a5547854a6191a2123d6147cb09f74523b5ff590c20dd74d"
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
  local image="329a0ece3838923450af268d7229d0db7b95b765320ba10d169185708f272124"
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
