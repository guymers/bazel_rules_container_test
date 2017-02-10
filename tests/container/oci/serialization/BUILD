package(default_visibility = ["//visibility:public"])

load("@io_bazel_rules_go//go:def.bzl", "go_test")

go_test(
    name = "image",
    srcs = ["image_test.go"],
    deps = [
        "//container/oci/serialization:go_default_library",
        "@com_github_opencontainers_image_spec//specs-go/v1:go_default_library",
    ],
)
