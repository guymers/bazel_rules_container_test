load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@io_bazel_stardoc//stardoc:stardoc.bzl", "stardoc")

stardoc(
    name = "test",
    input = "//container:test.bzl",
    out = "test.md",
    deps = [":refs"],
)

bzl_library(
    name = "refs",
    deps = [
        "@io_bazel_rules_docker//container:layer_tools.bzl",
        "@io_bazel_rules_docker//skylib:path.bzl",
        "@io_bazel_rules_docker//container:providers.bzl",
    ],
)
