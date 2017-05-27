def container_repositories():
  native.git_repository(
    name = "io_bazel_rules_go",
    remote = "https://github.com/bazelbuild/rules_go.git",
    commit = "4c9a52aba0b59511c5646af88d2f93a9c0193647", # 0.4.4
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
