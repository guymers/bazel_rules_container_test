load("@bazel_rules_container//container:container.bzl", "container_layer", "container_image")

genrule(
    name = "jessie_tar",
    srcs = ["@debian_jessie//file"],
    outs = ["jessie_extracted.tar"],
    cmd = "cat $< | xzcat >$@",
)

container_layer(
    name = "jessie_layer",
    tars = [":jessie_tar"],
)

container_image(
    name = "jessie",
    layers = [":jessie_layer"],
    visibility = ["//visibility:public"],
)
