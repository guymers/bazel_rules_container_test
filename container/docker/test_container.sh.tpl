# the contents of @io_bazel_rules_docker//container:incremental_load_template will be added above

readonly raw_mem_limit="%{mem_limit}"
readonly mem_limit="${raw_mem_limit:-256m}"

readonly image_id=$(cat "${RUNFILES}/%{image_digest}")
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

# ignore unset errors from empty arrays on old versions of bash
set +u

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

set -u

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
