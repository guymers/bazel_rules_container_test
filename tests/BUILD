licenses(["notice"])  # Apache 2.0

TEST_TARGETS = [
    "base_with_entrypoint",
    "base_with_volume",
    "derivative_with_cmd",
    "derivative_with_shadowed_cmd",
    "derivative_with_volume",
    "directory_with_tar_base",
    "files_base",
    "files_with_files_base",
    "files_with_tar_base",
    "tar_base",
    "tar_with_files_base",
    "tar_with_tar_base",
    "generated_tarball",
    "with_env",
    "with_double_env",
    "with_labels",
    "with_user",
    "workdir_with_tar_base",
    "link_with_files_base",
    "layer_from_tar"
]

PROG_LAYERS = ["prog", "prog_duplicate", "prog_no_renames"]

TEST_DATA = [
    "//tests/data:%s.tar" % t for t in TEST_TARGETS
] + [
    "//tests/data:%s_layer.layer" % t for t in PROG_LAYERS
] + [
    "//tests/data:%s_layer_fix.layer" % t for t in PROG_LAYERS
] + [
    "//tests/data:gen_image.tar",
    "//tests/data:dummy_image_info.tar",
    "//tests/data:extras_with_deb.tar",
]

sh_test(
    name = "build_test",
    size = "medium",
    srcs = [
        "build_test.sh",
    ],
    data = TEST_DATA + ["testenv.sh"],
    deps = [
        "@io_bazel//src/test/shell:bashunit",
    ],
)

sh_test(
    name = "fix_layer_test",
    size = "medium",
    srcs = [
        "fix_layer_test.sh",
    ],
    data = TEST_DATA + ["testenv.sh"],
    deps = [
        "@io_bazel//src/test/shell:bashunit",
    ],
)
