load("@bazel_rules_container//container:layer.bzl", "container_layer_from_tar")
load("@bazel_rules_container//container:image.bzl", "container_image")

LAYERS = [%{layers}]

[
    genrule(
        name = "%s_tar" % l,
        srcs = ["%s.%{layer_extension}" % l],
        outs = ["%s_extracted.tar" % l],
        cmd = "cat $< | zcat >$@",
    ) for l in LAYERS
]

[
    container_layer_from_tar(
        name = l,
        tar = ":%s_tar" % l,
    ) for l in LAYERS
]

container_image(
    name = "image",
    image_name = "%{image_name}",
    image_tag = "%{image_tag}",
    layers = LAYERS,
    config_file = "%{config_file}",
    visibility = ["//visibility:public"],
)
