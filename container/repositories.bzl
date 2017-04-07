def container_repositories():
  native.git_repository(
    name = "io_bazel_rules_go",
    remote = "https://github.com/bazelbuild/rules_go.git",
    commit = "2d9f328a9723baf2d037ba9db28d9d0e30683938",
  )

  native.git_repository(
    name = "docker2aci",
    remote = "https://github.com/guymers/docker2aci.git",
    tag = "v0.16.0-bazel",
  )

  native.new_git_repository(
    name = "skopeo",
    remote = "https://github.com/guymers/skopeo-builds.git",
    tag = "0.1.18",
    build_file_content = "exports_files(['skopeo', 'default-policy.json'])"
  )
