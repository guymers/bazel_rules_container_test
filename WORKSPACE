workspace(name = "bazel_rules_container")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

load("//container:repositories.bzl", "repositories")
repositories()

load("@io_bazel_rules_docker//repositories:repositories.bzl", docker_rules_repositories = "repositories")
docker_rules_repositories()

load("@io_bazel_rules_docker//repositories:deps.bzl", docker_rules_deps = "deps")
docker_rules_deps()

load("@io_bazel_stardoc//:setup.bzl", "stardoc_repositories")
stardoc_repositories()
