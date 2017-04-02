def container_repositories():
  native.git_repository(
    name = "io_bazel_rules_go",
    remote = "https://github.com/bazelbuild/rules_go.git",
    tag = "0.4.1",
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
