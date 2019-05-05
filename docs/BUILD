load("@io_bazel_skydoc//stardoc:stardoc.bzl", "stardoc")

# https://github.com/bazelbuild/skydoc/issues/166
stardoc(
    name = "docs",
    input = "//container:image.bzl",
    out = "image.html",
    semantic_flags = [
        "--dep_roots=bazel-bazel_container/"
        ],
)

#stardoc(
#    name = "docs",
#    input = [
#        "//container:layer.bzl",
#        "//container:image.bzl",
#        "//container:test.bzl",
#    ],
#    format = "html",
#    site_root = "/bazel_rules_container",
#)
