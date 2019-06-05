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
    url = "https://github.com/bazelbuild/bazel/archive/0.26.0.tar.gz",
    strip_prefix = "bazel-0.26.0",
    sha256 = "ffedd5a5ff830552c83a7a3613cea2836f2c80a0ac483d14e6f1ae19871931b8",
)

http_archive(
    name = "io_bazel_skydoc",
    url = "https://github.com/bazelbuild/skydoc/archive/e235d7d6dec0241261bdb13d7415f3373920e6fd.tar.gz",
    strip_prefix = "skydoc-e235d7d6dec0241261bdb13d7415f3373920e6fd",
    sha256 = "5a16ba5825d5ea9233cf6a266ae826ab4d5b68139fadcd9b0060046717743105",
)

load("@io_bazel_skydoc//:setup.bzl", "skydoc_repositories")
skydoc_repositories()

load("@io_bazel_rules_sass//:package.bzl", "rules_sass_dependencies")
rules_sass_dependencies()

load("@build_bazel_rules_nodejs//:defs.bzl", "node_repositories")
node_repositories()

load("@io_bazel_rules_sass//:defs.bzl", "sass_repositories")
sass_repositories()
