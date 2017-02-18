def container_repositories():
  native.git_repository(
    name = "io_bazel_rules_go",
    remote = "https://github.com/bazelbuild/rules_go.git",
    tag = "0.4.0",
  )

  native.new_git_repository(
    name = "skopeo",
    remote = "https://github.com/guymers/skopeo-builds.git",
    tag = "0.1.18",
    build_file_content = "exports_files(['skopeo'])"
  )
