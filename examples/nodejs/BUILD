load("@bazel_rules_container//container:layer.bzl", "container_layer")
load("@bazel_rules_container//container:image.bzl", "container_image")
load("//versions:versions.bzl", "NODEJS_VERSION")

container_layer(
    name = "files",
    directory = "/opt",
    files = ["@nodejs//:node-v" + NODEJS_VERSION + "-linux-x64"],
    symlinks = {
        "/usr/local/bin/node": "/opt/node-v" + NODEJS_VERSION + "-linux-x64/bin/node",
        "/usr/local/bin/npm": "/opt/node-v" + NODEJS_VERSION + "-linux-x64/lib/node_modules/npm/bin/npm-cli.js",
    },
)

container_image(
    name = "nodejs",
    base = "@debian_jessie//:image",
    layers = [":files"],
    visibility = ["//visibility:public"],
)
