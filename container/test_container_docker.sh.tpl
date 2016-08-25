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

cat > "${RUNFILES}/__test.sh" <<EOL
#!/bin/bash -e
mkdir /tmp/bazel_docker
tar -xf /bazel_docker/__runfiles.tar --strip-components=${components} --directory /tmp/bazel_docker
cd /tmp/bazel_docker
./${test_script_base}
EOL

docker_args="-m ${mem_limit} -v ${RUNFILES}:/bazel_docker:ro"

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

if [[ %{daemon} = true ]]; then
  echo "Running exec on daemon"
  readonly container_id=$("${DOCKER}" run -d $docker_args "$image")

  function cleanup {
    "${DOCKER}" stop "${container_id}" > /dev/null
    "${DOCKER}" rm "${container_id}" > /dev/null
  }
  trap cleanup EXIT

  OUTPUT=$("${DOCKER}" exec "$container_id" bash /bazel_docker/__test.sh)
else
  echo "Running as command"
  OUTPUT=$("${DOCKER}" run --rm $docker_args "$image" bash /bazel_docker/__test.sh)
fi

%{exit_code_compare_command}

%{diff_command}
