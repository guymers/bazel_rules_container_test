load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def repositories():
  http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "14ac30773fdb393ddec90e158c9ec7ebb3f8a4fd533ec2abbfd8789ad81a284b",
    strip_prefix = "rules_docker-0.12.1",
    urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.12.1/rules_docker-v0.12.1.tar.gz"],
  )

  http_archive(
    name = "io_bazel_stardoc",
    url = "https://github.com/bazelbuild/stardoc/archive/0.4.0.tar.gz",
    strip_prefix = "stardoc-0.4.0",
    sha256 = "6d07d18c15abb0f6d393adbd6075cd661a2219faab56a9517741f0fc755f6f3c",
  )
