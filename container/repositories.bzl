def container_repositories():
  native.http_archive(
    name = "io_bazel_rules_go",
    url = "https://github.com/bazelbuild/rules_go/releases/download/0.10.1/rules_go-0.10.1.tar.gz",
    sha256 = "4b14d8dd31c6dbaf3ff871adcd03f28c3274e42abc855cb8fb4d01233c0154dc",
  )

  native.http_archive(
    name = "io_bazel_rules_docker",
    sha256 = "6dede2c65ce86289969b907f343a1382d33c14fbce5e30dd17bb59bb55bb6593",
    strip_prefix = "rules_docker-0.4.0",
    url = "https://github.com/bazelbuild/rules_docker/archive/v0.4.0.tar.gz",
  )

  native.http_archive(
    name = "docker2aci",
    url = "https://github.com/guymers/docker2aci/archive/v0.17.1-bazel.tar.gz",
    sha256 = "b9d9ac69c550ecf50b7b36cbb51710a4b92d6acb557b5c17dad4680e935a4599",
    strip_prefix = "docker2aci-0.17.1-bazel",
  )
