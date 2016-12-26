load("@io_bazel_rules_go//go:def.bzl", "new_go_repository")

def container_repositories_go():
  new_go_repository(
    name = "com_github_opencontainers_image_spec",
    importpath = "github.com/opencontainers/image-spec",
    tag = "v1.0.0-rc3",
  )

  new_go_repository(
    name = "com_github_spf13_cobra",
    importpath = "github.com/spf13/cobra",
    commit = "37c3f8060359192150945916cbc2d72bce804b4d",
  )

  new_go_repository(
    name = "com_github_spf13_pflag",
    importpath = "github.com/spf13/pflag",
    commit = "103ce5cd2042f2fe629c1957abb64ab3e7f50235",
  )
