workspace(name = "bazel_rules_container")

git_repository(
    name = "io_bazel",
    remote = "https://github.com/bazelbuild/bazel.git",
    tag = "0.3.0",
)

git_repository(
    name = "io_bazel_rules_sass",
    remote = "https://github.com/bazelbuild/rules_sass.git",
    tag = "0.0.1",
)
load("@io_bazel_rules_sass//sass:sass.bzl", "sass_repositories")
sass_repositories()

git_repository(
    name = "io_bazel_skydoc",
    remote = "https://github.com/guymers/skydoc.git",
    commit = "8efb69d812a449d0c0c5713db2b26b319bbe44e3",
)
load("@io_bazel_skydoc//skylark:skylark.bzl", "skydoc_repositories")
skydoc_repositories()
