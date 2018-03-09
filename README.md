# Container Rules

## Overview

These build rules are used for building [Open Container Initiative](https://github.com/opencontainers/image-spec) containers with Bazel.

## Setup

To use these rules, add the following to your `WORKSPACE` file:

```python
http_archive(
    name = "bazel_rules_container",
    sha256 = "aa7ad550e2960143835c6a7d3bbc29e313aedf89ea879e5465e97f5d6a19e7f5",
    strip_prefix = "rules_rust-0.0.5",
    url = "https://github.com/guymers/bazel_rules_container/archive/0.7.0.tar.gz",
)
load("@bazel_rules_container//container:repositories.bzl", "container_repositories")
container_repositories()

load("@io_bazel_rules_go//go:def.bzl", "go_rules_dependencies", "go_register_toolchains")
go_rules_dependencies()
go_register_toolchains()

load("@bazel_rules_container//container:repositories_go.bzl", "container_repositories_go")
container_repositories_go()
```

You can now create an OCI image by:

```python
load("@io_bazel_rules_docker//docker:docker.bzl", "docker_pull")
load("@bazel_rules_container//container:layer.bzl", "container_layer")
load("@bazel_rules_container//container:image.bzl", "container_image")

NODEJS_VERSION = "6.9.5"

docker_pull(
    name = "base",
    registry = "gcr.io",
    repository = "distroless/cc",
    digest = "sha256:942eb947818e7e32200950b600cc94d5477b03e0b99bf732b4c1e2bba6eec717",
)

new_http_archive(
    name = "nodejs",
    url = "https://nodejs.org/dist/v" + NODEJS_VERSION + "/node-v" + NODEJS_VERSION + "-linux-x64.tar.xz",
    sha256 = "4831ba1a9f678f91dd7e2516eaa781341651b91ac908121db902f5355f0211d8",
    build_file_content = "exports_files(['node-v" + NODEJS_VERSION + "-linux-x64'])",
)

container_layer(
    name = "files",
    directory = "/opt",
    files = ["@nodejs//:node-v" + NODEJS_VERSION + "-linux-x64"],
    symlinks = {
        "./usr/local/bin/node": "/opt/node-v" + NODEJS_VERSION + "-linux-x64/bin/node",
        "./usr/local/bin/npm": "/opt/node-v" + NODEJS_VERSION + "-linux-x64/lib/node_modules/npm/bin/npm-cli.js",
    },
)

container_image(
    name = "nodejs",
    base = "@base//image",
    layers = [":files"],
)
```

Containers created via the Docker rules can be used as a base image and containers created with these rules can
be exported to be used by Docker rules.
