load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def repositories():
  http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "4521794f0fba2e20f3bf15846ab5e01d5332e587e9ce81629c7f96c793bb7036",
    strip_prefix = "rules_docker-0.14.4",
    urls = ["https://github.com/bazelbuild/rules_docker/releases/download/v0.14.4/rules_docker-v0.14.4.tar.gz"],
  )

  http_archive(
    name = "io_bazel_stardoc",
    url = "https://github.com/bazelbuild/stardoc/archive/0.4.0.tar.gz",
    strip_prefix = "stardoc-0.4.0",
    sha256 = "6d07d18c15abb0f6d393adbd6075cd661a2219faab56a9517741f0fc755f6f3c",
  )
