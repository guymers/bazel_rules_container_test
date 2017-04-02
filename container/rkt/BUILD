sh_binary(
    name = "docker2aci",
    srcs = ["docker2aci.sh"],
    deps = [":docker2aci_exec"],
    visibility = ["//visibility:public"],
)

sh_library(
    name = "docker2aci_exec",
    data = ["@docker2aci//:docker2aci"],
)

filegroup(
    name = "load_template",
    srcs = ["load.sh.tpl"],
    visibility = ["//visibility:public"],
)

# filegroup(
#     name = "test_container_template",
#     srcs = ["test_container.sh.tpl"],
#     visibility = ["//visibility:public"],
# )
