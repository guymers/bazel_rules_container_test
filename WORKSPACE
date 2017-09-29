workspace(name = "bazel_rules_container")

load("//container:repositories.bzl", "container_repositories")
container_repositories()

load("@io_bazel_rules_go//go:def.bzl", "go_repositories")
go_repositories()

load("//container:repositories_go.bzl", "container_repositories_go")
container_repositories_go()

load("@io_bazel_rules_docker//docker:docker.bzl", "docker_repositories")
docker_repositories()


# test and documentation repositories
git_repository(
    name = "io_bazel",
    remote = "https://github.com/bazelbuild/bazel.git",
    commit = "0b804c229363457b269dfb8cbe79269d77ab1988", # 0.6.0
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
    commit = "e9be81cf5be41e4200749f5d8aa2db7955f8aacc", # >0.1.3 <?
)
load("@io_bazel_skydoc//skylark:skylark.bzl", "skydoc_repositories")
skydoc_repositories()
