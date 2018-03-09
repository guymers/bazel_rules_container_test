workspace(name = "bazel_rules_container")

load("//container:repositories.bzl", "container_repositories")
container_repositories()

load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains")
go_rules_dependencies()
go_register_toolchains()

load("//container:repositories_go.bzl", "container_repositories_go")
container_repositories_go()

load("@io_bazel_rules_docker//docker:docker.bzl", "docker_repositories")
docker_repositories()


# test and documentation repositories
http_archive(
    name = "io_bazel",
    sha256 = "e5321afb93e75cfb55f6f9c34d44f15230f8103677aa48a76ce3e868ee490d8e",
    strip_prefix = "bazel-0.11.1",
    url = "https://github.com/bazelbuild/bazel/archive/0.11.1.tar.gz",
)

http_archive(
    name = "io_bazel_rules_sass",
    sha256 = "d614becbba18a76e481de230ec0c9895a4e7bb882b629789809b0f6eeb135d3b",
    strip_prefix = "rules_sass-b14e3d0fca3da0b809c75a076701163d2d47f53a",
    url = "https://github.com/bazelbuild/rules_sass/archive/b14e3d0fca3da0b809c75a076701163d2d47f53a.tar.gz", # 2018-02-24
)
load("@io_bazel_rules_sass//sass:sass.bzl", "sass_repositories")
sass_repositories()

http_archive(
    name = "io_bazel_skydoc",
    sha256 = "5b25189a44176f6da23d949a5213153f8e22071ac1aa041cd3fbeef3e8c3aac3",
    strip_prefix = "skydoc-bc93337cde60673dddb81abbdd28553245236cae",
    url = "https://github.com/bazelbuild/skydoc/archive/bc93337cde60673dddb81abbdd28553245236cae.tar.gz", # 2018-02-24
)
load("@io_bazel_skydoc//skylark:skylark.bzl", "skydoc_repositories")
skydoc_repositories()
