load("@io_bazel_rules_go//go:def.bzl", "go_repository")

def container_repositories_go():
  go_repository(
    name = "com_github_opencontainers_image_spec",
    importpath = "github.com/opencontainers/image-spec",
    commit = "ab7389ef9f50030c9b245bc16b981c7ddf192882", # v1.0.0
  )

  go_repository(
    name = "com_github_opencontainers_go_digest",
    importpath = "github.com/opencontainers/go-digest",
    commit = "eaa60544f31ccf3b0653b1a118b76d33418ff41b",
  )

  go_repository(
    name = "com_github_spf13_cobra",
    importpath = "github.com/spf13/cobra",
    commit = "b5d8e8f46a2f829f755b6e33b454e25c61c935e1",
  )

  go_repository(
    name = "com_github_spf13_pflag",
    importpath = "github.com/spf13/pflag",
    commit = "9ff6c6923cfffbcd502984b8e0c80539a94968b7",
  )
