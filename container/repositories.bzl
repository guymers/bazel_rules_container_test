def container_repositories():
  native.git_repository(
    name = "io_bazel_rules_go",
    remote = "https://github.com/bazelbuild/rules_go.git",
    commit = "936af5753ebcd7a1f05127678435389cc2e3db5d", # 0.5.0
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
