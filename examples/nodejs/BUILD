load("@io_bazel_rules_docker//container:container.bzl", "container_layer", "container_image", "container_push")
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
    #base = "@base//image",
    base = "//buster",
    layers = [":files"],
    visibility = ["//visibility:public"],
)

container_push(
    name = "push",
    format = "Docker",
    image = ":nodejs",
    registry = "localhost:5000",
    repository = "container/nodejs",
    tag = "example",
)
