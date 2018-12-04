load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def container_repositories():
  http_archive(
    name = "io_bazel_rules_go",
    url = "https://github.com/bazelbuild/rules_go/releases/download/0.16.3/rules_go-0.16.3.tar.gz",
    sha256 = "b7a62250a3a73277ade0ce306d22f122365b513f5402222403e507f2f997d421",
  )

  http_archive(
    name = "bazel_gazelle",
    url = "https://github.com/bazelbuild/bazel-gazelle/releases/download/0.15.0/bazel-gazelle-0.15.0.tar.gz",
    sha256 = "6e875ab4b6bf64a38c352887760f21203ab054676d9c1b274963907e0768740d",
  )

  http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "29d109605e0d6f9c892584f07275b8c9260803bf0c6fcb7de2623b2bedc910bd",
    strip_prefix = "rules_docker-0.5.1",
    url = "https://github.com/bazelbuild/rules_docker/archive/v0.5.1.tar.gz",
  )

  http_archive(
    name = "docker2aci",
    url = "https://github.com/guymers/docker2aci/archive/v0.17.1-bazel.tar.gz",
    sha256 = "b9d9ac69c550ecf50b7b36cbb51710a4b92d6acb557b5c17dad4680e935a4599",
    strip_prefix = "docker2aci-0.17.1-bazel",
  )
