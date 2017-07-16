#!/bin/bash
#
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

set -e

# This is a generated file that tests a container image built by "container_image".
# From bazel/tools/build_defs/docker/incremental_load.sh.tpl

RUNFILES="${PYTHON_RUNFILES:-${BASH_SOURCE[0]}.runfiles}"

DOCKER="${DOCKER:-docker}"

# List all images identifier (only the identifier) from the local
# docker registry.
IMAGES="$("${DOCKER}" images -aq)"
IMAGE_LEN=$(for i in $IMAGES; do echo -n $i | wc -c; done | sort -g | head -1 | xargs)

[ -n "$IMAGE_LEN" ] || IMAGE_LEN=64

function incr_load() {
  # Load a layer if and only if the layer is not in "$IMAGES", that is
  # in the local docker registry.
  name=$(cat ${RUNFILES}/$1)
  if (echo "$IMAGES" | grep -q ^${name:0:$IMAGE_LEN}$); then
    echo "Skipping $name, already loaded."
  else
    echo "Loading $name..."
    "${DOCKER}" load -i ${RUNFILES}/$2
  fi
}

# List of 'incr_load' statements for all layers.
# This generated and injected by docker_build.
%{load_statements}

readonly raw_mem_limit="%{mem_limit}"
readonly mem_limit="${raw_mem_limit:-256m}"

readonly image_id=$(cat "${RUNFILES}/%{image_name}")
readonly image="sha256:$image_id"
readonly test_script="${RUNFILES}/%{test_script}"

readonly test_files=(%{test_files})
readonly full_test_files=("${test_files[@]/#/${RUNFILES}/}")

tar -chf "${RUNFILES}/__runfiles.tar" "${test_script}" "${full_test_files[@]}" > /dev/null

readonly test_script_base=$(basename "${test_script}")
readonly test_dir=$(dirname "${test_script}")
readonly slashes="${test_dir//[^\/]}"
readonly components="${#slashes}"

readonly tmp_dir=/tmp/bazel_docker
readonly cmd="mkdir -p \"$tmp_dir\" && tar -xf - --strip-components=\"${components}\" -C \"$tmp_dir\" && cd \"$tmp_dir\" && bash \"${test_script_base}\""

docker_args="-m ${mem_limit}"

readonly env=(%{env})
for e in "${env[@]}"; do
  docker_args+=" -e $e"
done

readonly volumes=(%{volumes})
for v in "${volumes[@]}"; do
  docker_args+=" -v ${RUNFILES}/${v%=*}:${v#*=}:ro"
done

readonly options=(%{options})
for o in "${options[@]}"; do
  docker_args+=" $o"
done

if [[ %{read_only} = true ]]; then
  docker_args+=" --read-only --tmpfs /run --tmpfs /tmp"

  readonly tmpfs_directories=(%{tmpfs_directories})
  for d in "${tmpfs_directories[@]}"; do
    docker_args+=" --tmpfs $d"
  done
fi

if [[ %{daemon} = true ]]; then
  echo "Running exec on daemon"
  echo "Starting container: ${DOCKER} run -d $docker_args $image"
  readonly container_id=$("${DOCKER}" run -d $docker_args "$image")

  function cleanup {
    "${DOCKER}" stop "${container_id}" > /dev/null
    "${DOCKER}" rm "${container_id}" > /dev/null
  }
  trap cleanup EXIT

  echo "Container started: $container_id"
  echo "Running exec: ${DOCKER} exec $container_id"

  set +e
  OUTPUT=$(cat "${RUNFILES}/__runfiles.tar" | "${DOCKER}" exec -i "$container_id" bash -c "$cmd")
  EXIT_CODE=$?
  LOGS=$("${DOCKER}" logs "$container_id")
else
  echo "Running as command"
  echo "Run command: ${DOCKER} run --rm $docker_args $image"

  set +e
  OUTPUT=$(cat "${RUNFILES}/__runfiles.tar" | "${DOCKER}" run -i --rm $docker_args "$image" bash -c "$cmd")
  EXIT_CODE=$?
  LOGS=""
fi

# dont need to set e back on

%{exit_code_compare_command}

%{diff_command}
