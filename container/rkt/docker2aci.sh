#!/bin/bash
set -e
set -o pipefail

readonly BAZEL_DIR="$0.runfiles"
[ -d "$BAZEL_DIR" ] && DIR="$BAZEL_DIR" || DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
readonly docker2aci="$DIR/docker2aci/docker2aci"

readonly oci_image="$1"

# docker2aci cannot read oci images...
readonly loaded_iamge=$(docker load -i "$oci_image" | tail -n1 | sed -re 's/^Loaded image: (.+)$/\1/')
docker save -o tmp.tar "$loaded_iamge"

readonly docker_image="tmp.tar"
readonly aci_image="$2"

readonly aci_image_name=$("$docker2aci" -compression none "$docker_image" | tail -n1)
mv "$aci_image_name" "$aci_image"
rm tmp.tar
