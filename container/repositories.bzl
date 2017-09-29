def container_repositories():
  native.git_repository(
    name = "io_bazel_rules_go",
    remote = "https://github.com/bazelbuild/rules_go.git",
    commit = "2ffc49e4b9a3fb71fef5e94fa2da5bc1eca4f44d", # 0.5.5
  )

  native.git_repository(
    name = "io_bazel_rules_docker",
    remote = "https://github.com/bazelbuild/rules_docker.git",
    commit = "9dd92c73e7c8cf07ad5e0dca89a3c3c422a3ab7d", # 0.3.0
  )

  native.git_repository(
    name = "docker2aci",
    remote = "https://github.com/guymers/docker2aci.git",
    tag = "v0.16.0-bazel",
  )
