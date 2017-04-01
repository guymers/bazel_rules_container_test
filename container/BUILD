licenses(["notice"])  # Apache 2.0

exports_files(
    [
        "container.bzl",
        "pull.bzl",
        "test.bzl",
    ],
    visibility = ["//docs:__subpackages__"],
)

py_binary(
    name = "fix_layer",
    srcs = ["fix_layer.py"],
    visibility = ["//visibility:public"],
    deps = [
        "@bazel_tools//third_party/py/gflags",
    ],
)

py_binary(
    name = "create_image",
    srcs = ["create_image.py"],
    visibility = ["//visibility:public"],
    deps = [
        ":utils",
        "//bazel/tools/build_defs/pkg:archive",
        "@bazel_tools//third_party/py/gflags",
    ],
)

py_binary(
    name = "assemble_image",
    srcs = ["assemble_image.py"],
    visibility = ["//visibility:public"],
    deps = [
        ":utils",
        "//bazel/tools/build_defs/pkg:archive",
        "@bazel_tools//third_party/py/gflags",
    ],
)

py_library(
    name = "utils",
    srcs = ["utils.py"],
)

filegroup(
    name = "docker_incremental_load_template",
    srcs = ["docker_incremental_load.sh.tpl"],
    visibility = ["//visibility:public"],
)

filegroup(
    name = "docker_test_container_template",
    srcs = ["test_container_docker.sh.tpl"],
    visibility = ["//visibility:public"],
)
