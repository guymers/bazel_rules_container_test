load("@io_bazel_rules_go//go:def.bzl", "go_library")

go_library(
    name = "go_default_library",
    srcs = [
        "command.go",
        "image.go",
        "operations.go",
    ],
    importpath = "github.com/guymers/bazel_container/container/oci/serialization",
    visibility = ["//visibility:public"],
    deps = [
        "@com_github_opencontainers_go_digest//:go_default_library",
        "@com_github_opencontainers_image_spec//specs-go/v1:go_default_library",
        "@com_github_spf13_cobra//:go_default_library",
    ],
)
