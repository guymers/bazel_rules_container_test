load("@bazel_gazelle//:deps.bzl", "go_repository")

def container_repositories_go():
  go_repository(
    name = "com_github_opencontainers_image_spec",
    importpath = "github.com/opencontainers/image-spec",
    commit = "d60099175f88c47cd379c4738d158884749ed235", # v1.0.1
  )

  go_repository(
    name = "com_github_opencontainers_go_digest",
    importpath = "github.com/opencontainers/go-digest",
    commit = "279bed98673dd5bef374d3b6e4b09e2af76183bf", # v1.0.0-rc1
  )

  go_repository(
    name = "com_github_spf13_cobra",
    importpath = "github.com/spf13/cobra",
    commit = "c6c44e6fdcc30161c7f4480754da7230d01c06e3", # 2018-03-02
  )

  go_repository(
    name = "com_github_spf13_pflag",
    importpath = "github.com/spf13/pflag",
    commit = "ee5fd03fd6acfd43e44aea0b4135958546ed8e73", # 2018-02-21
  )

  go_repository(
    name = "com_github_inconshreveable_mousetrap",
    importpath = "github.com/inconshreveable/mousetrap",
    commit = "76626ae9c91c4f2a10f34cad8ce83ea42c93bb75", # 2014-10-18
  )
