def container_repositories():
  native.git_repository(
    name = "io_bazel_rules_go",
    remote = "https://github.com/bazelbuild/rules_go.git",
    commit = "936af5753ebcd7a1f05127678435389cc2e3db5d", # 0.5.0
  )

  native.git_repository(
    name = "io_bazel_rules_docker",
    remote = "https://github.com/bazelbuild/rules_docker.git",
    commit = "79aa5de0eb7348876316c537f7cec26bae02cfab", # Jul 15, 2017
  )

  native.git_repository(
    name = "docker2aci",
    remote = "https://github.com/guymers/docker2aci.git",
    tag = "v0.16.0-bazel",
  )
