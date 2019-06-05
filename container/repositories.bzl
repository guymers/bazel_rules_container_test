load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def container_repositories():
  http_archive(
    name = "io_bazel_rules_go",
    url = "https://github.com/bazelbuild/rules_go/releases/download/0.18.5/rules_go-0.18.5.tar.gz",
    sha256 = "a82a352bffae6bee4e95f68a8d80a70e87f42c4741e6a448bec11998fcc82329",
  )

  http_archive(
    name = "bazel_gazelle",
    url = "https://github.com/bazelbuild/bazel-gazelle/releases/download/0.17.0/bazel-gazelle-0.17.0.tar.gz",
    sha256 = "3c681998538231a2d24d0c07ed5a7658cb72bfb5fd4bf9911157c0e9ac6a2687",
  )

  http_archive(
    name = "io_bazel_rules_docker",
    url = "https://github.com/bazelbuild/rules_docker/archive/v0.7.0.tar.gz",
    sha256 = "aed1c249d4ec8f703edddf35cbe9dfaca0b5f5ea6e4cd9e83e99f3b0d1136c3d",
    strip_prefix = "rules_docker-0.7.0",
  )

  http_archive(
    name = "docker2aci",
    url = "https://github.com/guymers/docker2aci/archive/v0.17.2-bazel.tar.gz",
    sha256 = "785a80f5c71fb943fbdfa8f1bd5777f78615d3e2afc0ef86e7b908cdcb0266d4",
    strip_prefix = "docker2aci-0.17.2-bazel",
  )
