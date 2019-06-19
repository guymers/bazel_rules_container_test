package(
    default_visibility = [
        "//tests:__subpackages__",
    ],
)

load("//tests/data:utils.bzl", "generate_deb")
load(
    "//container:layer.bzl",
    "container_layer",
    "container_layer_from_tar",
)
load("//container:image.bzl", "container_image")

filegroup(
    name = "srcs",
    srcs = glob(["**"]) + [
        "//tests/data/test:srcs",
    ],
)

genrule(
    name = "gen",
    outs = ["gen.out"],
    cmd = "echo generated > $@",
)

container_layer(
    name = "foo_file",
    files = ["foo"],
)

container_image(
    name = "dummy_image_info",
    image_name = "repo/dummy",
    image_tag = "9000",
    layers = [":foo_file"],
)

container_layer(
    name = "gen_file",
    files = [":gen"],
    mode = "0644",
)

container_image(
    name = "gen_image",
    layers = [":gen_file"],
)

container_layer(
    name = "foo_file_mode",
    files = ["foo"],
    mode = "0644",
)

container_image(
    name = "files_base",
    layers = [":foo_file_mode"],
)

container_layer(
    name = "bar_file_mode",
    files = ["bar"],
    mode = "0644",
)

container_image(
    name = "files_with_files_base",
    base = ":files_base",
    layers = [":bar_file_mode"],
)

container_layer(
    name = "one_tar",
    tars = ["one.tar"],
)

container_image(
    name = "tar_base",
    layers = [":one_tar"],
)

container_layer(
    name = "two_tar",
    tars = ["two.tar"],
)

container_image(
    name = "tar_with_tar_base",
    base = ":tar_base",
    layers = [":two_tar"],
)

container_layer(
    name = "two_tar_foo",
    directory = "/foo",
    tars = ["two.tar"],
)

container_image(
    name = "directory_with_tar_base",
    base = ":tar_base",
    layers = [":two_tar_foo"],
)

container_image(
    name = "workdir_with_tar_base",
    base = ":tar_base",
    workdir = "/tmp",
)

container_layer(
    name = "files_bar",
    files = ["bar"],
    mode = "0644",
)

container_image(
    name = "files_with_tar_base",
    base = ":tar_base",
    layers = [":files_bar"],
)

container_image(
    name = "tar_with_files_base",
    base = ":files_base",
    layers = [":two_tar"],
)

container_layer(
    name = "base_with_entrypoint_layer",
    files = ["bar"],
    mode = "0644",
    tars = ["two.tar"],
)

container_image(
    name = "base_with_entrypoint",
    entrypoint = ["/bar"],
    layers = [":base_with_entrypoint_layer"],
    ports = ["8080"],
)

container_layer(
    name = "derivative_with_shadowed_cmd_layer",
    files = ["foo"],
    mode = "0644",
)

container_image(
    name = "derivative_with_shadowed_cmd",
    base = ":base_with_entrypoint",
    cmd = ["shadowed-arg"],
    layers = [":derivative_with_shadowed_cmd_layer"],
)

container_image(
    name = "derivative_with_cmd",
    base = ":derivative_with_shadowed_cmd",
    cmd = [
        "arg1",
        "arg2",
    ],
    layers = [":one_tar"],
    ports = ["80/tcp"],
)

container_layer(
    name = "base_with_volume_layer",
    files = [
        "bar",
        "foo",
    ],
    mode = "0644",
)

container_image(
    name = "base_with_volume",
    layers = [":base_with_volume_layer"],
    volumes = ["/logs"],
)

container_image(
    name = "derivative_with_volume",
    base = ":base_with_volume",
    volumes = [
        "/asdf",
        "/blah",
    ],
)

py_binary(
    name = "extras_gen",
    srcs = ["extras_gen.py"],
    deps = ["@bazel_tools//tools/build_defs/pkg:archive"],
)

genrule(
    name = "extras",
    outs = ["extras.tar"],
    cmd = "$(location :extras_gen) $@",
    tools = [":extras_gen"],
)

container_layer(
    name = "extras_layer",
    tars = [
        ":extras",
    ],
)

container_image(
    name = "generated_tarball",
    layers = [":extras_layer"],
)

container_image(
    name = "with_env",
    base = ":base_with_volume",
    env = {
        "foo": "/asdf",
        "bar": "blah blah blah",
    },
)

container_image(
    name = "with_double_env",
    base = ":with_env",
    env = {
        "baz": "${foo} $bar",
    },
)

container_image(
    name = "with_labels",
    base = ":base_with_volume",
    labels = {
        "app": "foo",
        "type": "bar",
    },
)

container_image(
    name = "with_user",
    base = ":base_with_volume",
    user = "nobody",
)

container_layer(
    name = "link_with_files_base_layer",
    symlinks = {
        "/usr/bin/java": "/bar",
    },
)

container_image(
    name = "link_with_files_base",
    base = ":files_base",
    layers = [":link_with_files_base_layer"],
)

container_layer_from_tar(
    name = "layer_from_tar_layer",
    tar = "one.tar",
)

container_image(
    name = "layer_from_tar",
    layers = [":layer_from_tar_layer"],
)

# Generate a dummy debian package with a test/ directory
py_binary(
    name = "gen_deb",
    srcs = ["gen_deb.py"],
)

generate_deb(
    name = "extras_deb",
)

# Bot gen.deb and test-data has a test directory, it should appear
# only once in the resulting layer.
container_layer(
    name = "extras_with_deb_layer",
    debs = [":extras_deb.deb"],
    tars = ["extras.tar"],
)

container_image(
    name = "extras_with_deb",
    layers = [":extras_with_deb_layer"],
)
