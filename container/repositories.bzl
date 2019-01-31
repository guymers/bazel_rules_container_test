load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def container_repositories():
  http_archive(
    name = "io_bazel_rules_go",
    url = "https://github.com/bazelbuild/rules_go/releases/download/0.17.0/rules_go-0.17.0.tar.gz",
    sha256 = "492c3ac68ed9dcf527a07e6a1b2dcbf199c6bf8b35517951467ac32e421c06c1",
  )

  http_archive(
    name = "bazel_gazelle",
    url = "https://github.com/bazelbuild/bazel-gazelle/releases/download/0.16.0/bazel-gazelle-0.16.0.tar.gz",
    sha256 = "7949fc6cc17b5b191103e97481cf8889217263acf52e00b560683413af204fcb",
  )

  http_archive(
    name = "io_bazel_rules_docker",
    url = "https://github.com/bazelbuild/rules_docker/archive/v0.7.0.tar.gz",
    sha256 = "aed1c249d4ec8f703edddf35cbe9dfaca0b5f5ea6e4cd9e83e99f3b0d1136c3d",
    strip_prefix = "rules_docker-0.7.0",
  )

  http_archive(
    name = "docker2aci",
    url = "https://github.com/guymers/docker2aci/archive/v0.17.1-bazel.tar.gz",
    sha256 = "b9d9ac69c550ecf50b7b36cbb51710a4b92d6acb557b5c17dad4680e935a4599",
    strip_prefix = "docker2aci-0.17.1-bazel",
  )
