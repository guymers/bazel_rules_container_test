load("@io_bazel_skydoc//skylark:skylark.bzl", "skylark_doc")

filegroup(
    name = "files",
    srcs = ["//container:container.bzl"],
)

filegroup(
    name = "tests",
    srcs = ["//container:test.bzl"],
)

# bazel build //docs && unzip -o bazel-bin/docs/docs-skydoc.zip && mv container.md README.md && mv test.md docs/
skylark_doc(
    name = "docs",
    srcs = [":files", ":tests"],
    format = "markdown",
)

skylark_doc(
    name = "html",
    srcs = [":files"],
    format = "html",
)
