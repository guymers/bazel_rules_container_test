workspace(name = "bazel_rules_container")

load("//container:repositories.bzl", "repositories")
repositories()

load("@io_bazel_rules_docker//repositories:repositories.bzl", container_repositories = "repositories")
container_repositories()

load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")
container_deps()

load("@io_bazel_rules_docker//repositories:pip_repositories.bzl", "pip_deps")
pip_deps()

load("@io_bazel_stardoc//:setup.bzl", "stardoc_repositories")
stardoc_repositories()
