load("@io_bazel_skydoc//skylark:skylark.bzl", "skylark_doc")

BZL_FILES = [
    "layer",
    "image",
    "test",
]

[
    filegroup(
        name = f,
        srcs = ["//container:" + f + ".bzl"],
    )
    for f in BZL_FILES
]

skylark_doc(
    name = "docs",
    srcs = [":" + f for f in BZL_FILES],
    format = "markdown",
)

skylark_doc(
    name = "html",
    srcs = [":" + f for f in BZL_FILES],
    format = "html",
)
