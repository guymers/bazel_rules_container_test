load("@io_bazel_rules_docker//container:container.bzl", "container_layer", "container_image")

package(default_visibility = ["//visibility:public"])

genrule(
  name = "buster_tar",
  srcs = ["@debian_buster//file"],
  outs = ["buster_extracted.tar"],
  cmd = "cat $< | xzcat >$@",
)
container_layer(
  name = "buster_layer",
  tars = [":buster_tar"],
)
container_image(
  name = "buster",
  layers = [":buster_layer"],
)
