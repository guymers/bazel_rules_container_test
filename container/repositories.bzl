def container_repositories():
  native.http_archive(
    name = "io_bazel_rules_go",
    url = "https://github.com/bazelbuild/rules_go/releases/download/0.8.1/rules_go-0.8.1.tar.gz",
    sha256 = "90bb270d0a92ed5c83558b2797346917c46547f6f7103e648941ecdb6b9d0e72",
  )

  native.git_repository(
    name = "io_bazel_rules_docker",
    remote = "https://github.com/bazelbuild/rules_docker.git",
    commit = "9dd92c73e7c8cf07ad5e0dca89a3c3c422a3ab7d", # 0.3.0
  )

  native.http_archive(
    name = "docker2aci",
    url = "https://github.com/guymers/docker2aci/archive/v0.17.1-bazel.tar.gz",
    sha256 = "b9d9ac69c550ecf50b7b36cbb51710a4b92d6acb557b5c17dad4680e935a4599",
    strip_prefix = "docker2aci-0.17.1-bazel",
  )
