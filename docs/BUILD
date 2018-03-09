load("@io_bazel_skydoc//skylark:skylark.bzl", "skylark_doc")

skylark_doc(
    name = "docs",
    srcs = [
        "//container:layer.bzl",
        "//container:image.bzl",
        "//container:test.bzl",
    ],
    format = "html",
    site_root = "/bazel_rules_container",
)
