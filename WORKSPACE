workspace(name = "bazel_rules_container")

load("//container:repositories.bzl", "container_repositories")
container_repositories()

load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains")
go_rules_dependencies()
go_register_toolchains()

load("//container:repositories_go.bzl", "container_repositories_go")
container_repositories_go()

load("@io_bazel_rules_docker//docker:docker.bzl", "docker_repositories")
docker_repositories()


# test and documentation repositories
git_repository(
    name = "io_bazel",
    remote = "https://github.com/bazelbuild/bazel.git",
    commit = "f4d58293c69e9359141576d2da88665dc63f2467", # 0.9.0
)

git_repository(
    name = "io_bazel_rules_sass",
    remote = "https://github.com/bazelbuild/rules_sass.git",
    commit = "bff806df05ea9e8b523a16e4bb83cdd110b077ed", # 0.0.3
)
load("@io_bazel_rules_sass//sass:sass.bzl", "sass_repositories")
sass_repositories()

git_repository(
    name = "io_bazel_skydoc",
    remote = "https://github.com/bazelbuild/skydoc.git",
    commit = "b36d22cc4436a7a7933e36a111bfc00fd494b9fb", # 0.1.4
)
load("@io_bazel_skydoc//skylark:skylark.bzl", "skydoc_repositories")
skydoc_repositories()
