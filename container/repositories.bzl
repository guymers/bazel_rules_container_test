load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def container_repositories():
  http_archive(
    name = "io_bazel_rules_go",
    urls = [
      "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/0.18.6/rules_go-0.18.6.tar.gz",
      "https://github.com/bazelbuild/rules_go/releases/download/0.18.6/rules_go-0.18.6.tar.gz",
    ],
    sha256 = "f04d2373bcaf8aa09bccb08a98a57e721306c8f6043a2a0ee610fd6853dcde3d",
  )

  http_archive(
    name = "bazel_gazelle",
    url = "https://github.com/bazelbuild/bazel-gazelle/releases/download/0.17.0/bazel-gazelle-0.17.0.tar.gz",
    sha256 = "3c681998538231a2d24d0c07ed5a7658cb72bfb5fd4bf9911157c0e9ac6a2687",
  )

  http_archive(
    name = "io_bazel_rules_docker",
    url = "https://github.com/bazelbuild/rules_docker/archive/709b523533283fdfdf2dce480cce2cb50e1709d3.tar.gz",
    sha256 = "590787599c97703860f5d6e4ab513b9e25bdfd0fbe235125c81af4213aaa3053",
    strip_prefix = "rules_docker-709b523533283fdfdf2dce480cce2cb50e1709d3",
  )

  http_archive(
    name = "docker2aci",
    url = "https://github.com/guymers/docker2aci/archive/v0.17.2-bazel.tar.gz",
    sha256 = "785a80f5c71fb943fbdfa8f1bd5777f78615d3e2afc0ef86e7b908cdcb0266d4",
    strip_prefix = "docker2aci-0.17.2-bazel",
  )
