load("@bazel_rules_container//container:container.bzl", "container_layer", "container_image")

VERSION = "6.2.1"

container_layer(
    name = "files",
    directory = "/opt",
    files = ["@nodejs//:node-v" + VERSION + "-linux-x64"],
    symlinks = {
        "/usr/local/bin/node": "/opt/node-v" + VERSION + "-linux-x64/bin/node",
        "/usr/local/bin/npm": "/opt/node-v" + VERSION + "-linux-x64/lib/node_modules/npm/bin/npm-cli.js",
    },
)

container_image(
    name = "nodejs",
    base = "//base:jessie",
    layers = [":files"],
    visibility = ["//visibility:public"],
)
