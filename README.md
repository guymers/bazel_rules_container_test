# Container Testing Rule

## Overview

Provides a `container_test` rule that can test containers built with [rules_docker](https://github.com/bazelbuild/rules_docker).

## Setup

After the `rules_docker` setup add the following to your `WORKSPACE` file:

```python
http_archive(
    name = "bazel_rules_container_test",
    sha256 = "0ea03839bf059c0ec7c4f95cb6cb048b84094b180b051c737cbef9ca150bcc0b",
    strip_prefix = "bazel_rules_container_test-0.11.0",
    url = "https://github.com/guymers/bazel_rules_container/archive/0.11.0.tar.gz",
)
```

## Example

```python
load("@bazel_rules_container_test//container:test.bzl", "container_test")

container_test(
    name = "nodejs",
    read_only = False,
    size = "small",
    files = [
        "project/index.js",
        "project/package.json",
    ],
    golden = "output.txt",
    image = "//nodejs",
    test = "test.sh",
)
```

## Docs

<!-- Generated with Stardoc: http://skydoc.bazel.build -->

<a name="#container_test"></a>

## container_test

<pre>
container_test(<a href="#container_test-name">name</a>, <a href="#container_test-daemon">daemon</a>, <a href="#container_test-env">env</a>, <a href="#container_test-error">error</a>, <a href="#container_test-files">files</a>, <a href="#container_test-golden">golden</a>, <a href="#container_test-image">image</a>, <a href="#container_test-incremental_load_template">incremental_load_template</a>, <a href="#container_test-mem_limit">mem_limit</a>,
               <a href="#container_test-options">options</a>, <a href="#container_test-read_only">read_only</a>, <a href="#container_test-regex">regex</a>, <a href="#container_test-test">test</a>, <a href="#container_test-tmpfs_directories">tmpfs_directories</a>, <a href="#container_test-volume_files">volume_files</a>, <a href="#container_test-volume_mounts">volume_mounts</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| daemon |  -   | Boolean | optional | False |
| env |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| error |  -   | Integer | optional | 0 |
| files |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| golden |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| image |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| incremental_load_template |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | @io_bazel_rules_docker//container:incremental_load_template |
| mem_limit |  -   | String | optional | "" |
| options |  -   | List of strings | optional | [] |
| read_only |  -   | Boolean | optional | True |
| regex |  -   | Boolean | optional | False |
| test |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| tmpfs_directories |  -   | List of strings | optional | [] |
| volume_files |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| volume_mounts |  -   | List of strings | optional | [] |
