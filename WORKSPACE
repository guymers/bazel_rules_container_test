workspace(name = "bazel_rules_container")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

load("//container:repositories.bzl", "container_repositories")
container_repositories()

load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains")
go_rules_dependencies()
go_register_toolchains()


load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
gazelle_dependencies()


load("@io_bazel_rules_docker//container:container.bzl", container_repositories = "repositories")
container_repositories()


load("//container:repositories_go.bzl", "container_repositories_go")
container_repositories_go()


# test and documentation repositories
http_archive(
    name = "io_bazel",
    url = "https://github.com/bazelbuild/bazel/archive/0.20.0.tar.gz",
    strip_prefix = "bazel-0.20.0",
    sha256 = "f59608e56b0b68fe9b18661ae3d10f6a61aaa5f70ed11f2db52e7bc6db516454",
)


http_archive(
    name = "io_bazel_rules_sass",
    url = "https://github.com/bazelbuild/rules_sass/archive/1.15.1.tar.gz",
    strip_prefix = "rules_sass-1.15.1",
    sha256 = "438b26d1047fd51169c95e2a473140065cf34d3726ce2c23ebc5a953785df998",
)

load("@io_bazel_rules_sass//:package.bzl", "rules_sass_dependencies")
rules_sass_dependencies()
load("@build_bazel_rules_nodejs//:defs.bzl", "node_repositories")
node_repositories()

load("@io_bazel_rules_sass//:defs.bzl", "sass_repositories")
sass_repositories()


http_archive(
    name = "io_bazel_skydoc",
    url = "https://github.com/bazelbuild/skydoc/archive/0.2.0.tar.gz",
    strip_prefix = "skydoc-0.2.0",
    sha256 = "19eb6c162075707df5703c274d3348127625873dbfa5ff83b1ef4b8f5dbaa449",
)

load("@io_bazel_skydoc//skylark:skylark.bzl", "skydoc_repositories")
skydoc_repositories()
