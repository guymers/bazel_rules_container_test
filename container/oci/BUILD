package(default_visibility = ["//visibility:public"])

load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_binary(
    name = "image",
    embed = [":go_default_library"],
)

go_library(
    name = "go_default_library",
    srcs = ["image.go"],
    importpath = "github.com/guymers/bazel_container/container/oci",
    deps = ["//container/oci/serialization:go_default_library"],
)
