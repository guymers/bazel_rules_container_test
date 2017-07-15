load("@bazel_rules_container//container:layer.bzl", "container_layer")
load("@bazel_rules_container//container:image.bzl", "container_image")
load("@io_bazel_rules_docker//docker:docker.bzl", "docker_push")
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
    base = "@base//image",
    layers = [":files"],
    visibility = ["//visibility:public"],
)

docker_push(
    name = "push",
    image = ":nodejs",
    registry = "localhost:5000",
    repository = "container/nodejs",
    tag = "example",
)
