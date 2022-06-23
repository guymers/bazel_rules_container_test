load("@io_bazel_rules_docker//container:container.bzl", "container_layer", "container_image")

package(default_visibility = ["//visibility:public"])

genrule(
  name = "debian_tar",
  srcs = ["@debian_bullseye//file"],
  outs = ["debian_extracted.tar"],
  cmd = "cat $< | xzcat >$@",
)
container_layer(
  name = "debian_layer",
  tars = [":debian_tar"],
)
container_image(
  name = "debian",
  layers = [":debian_layer"],
)
