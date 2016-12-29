def container_repositories():
  native.git_repository(
    name = "io_bazel_rules_go",
    remote = "https://github.com/bazelbuild/rules_go.git",
    tag = "0.3.2",
  )

  native.git_repository(
    name = "skopeo",
    remote = "https://github.com/guymers/skopeo.git",
    commit = "v0.1.17-bazel",
  )
