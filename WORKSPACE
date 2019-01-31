workspace(name = "bazel_rules_container")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

load("//container:repositories.bzl", "container_repositories")
container_repositories()

load("@io_bazel_rules_go//go:deps.bzl", "go_rules_dependencies", "go_register_toolchains")
go_rules_dependencies()
go_register_toolchains()


load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")
gazelle_dependencies()


load("@io_bazel_rules_docker//repositories:repositories.bzl", docker_repositories = "repositories")
docker_repositories()


load("//container:repositories_go.bzl", "container_repositories_go")
container_repositories_go()


# test and documentation repositories
http_archive(
    name = "io_bazel",
    url = "https://github.com/bazelbuild/bazel/archive/0.22.0.tar.gz",
    strip_prefix = "bazel-0.22.0",
    sha256 = "af714cc650c5aa04d1d29748f89e57f1ce5775551c379c3fcf8acb3e7a36777e",
)


http_archive(
    name = "io_bazel_rules_sass",
    url = "https://github.com/bazelbuild/rules_sass/archive/1.16.1.tar.gz",
    strip_prefix = "rules_sass-1.16.1",
    sha256 = "f42aac17f49b28a1bd12dec0fbc3254ccd7244f3ac9b378d340993bfff1f8301",
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
