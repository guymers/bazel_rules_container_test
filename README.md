

<!---
Documentation generated by Skydoc
-->
<h1>Open Container Initiative Image Format support for Bazel</h1>


<nav class="toc">
  <h2><a href="#overview">Overview</a></h2>
  <h2>Rules</h2>
  <ul>
    <li><a href="#container_layer">container_layer</a></li>
    <li><a href="#container_layer_debian_stretch_symlink_fix">container_layer_debian_stretch_symlink_fix</a></li>
    <li><a href="#container_layer_from_tar">container_layer_from_tar</a></li>
  </ul>
</nav>
<hr>

<a name="overview"></a>
## Overview

These rules are used for building [OCI images](https://github.com/opencontainers/image-spec).

The `container_image` rule constructs a tarball which conforms to [v0.2.0](https://github.com/opencontainers/image-spec/blob/v0.2.0/serialization.md)
of the OCI Image Specification. Currently [Docker](https://docker.com) is the
only container runtime which is able to load these images.

Each image can contain multiple layers which can be created via the
`container_layer` rule.

<a name="container_layer"></a>
## container_layer

<pre>
container_layer(<a href="#container_layer.name">name</a>, <a href="#container_layer.data_path">data_path</a>, <a href="#container_layer.debs">debs</a>, <a href="#container_layer.directory">directory</a>, <a href="#container_layer.files">files</a>, <a href="#container_layer.mode">mode</a>, <a href="#container_layer.symlinks">symlinks</a>, <a href="#container_layer.tars">tars</a>)
</pre>

Create a tarball that can be used as a layer in a container image.


<a name="container_layer_outputs"></a>
### Outputs


<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr>
      <td><code>%{name}.layer</code></td>
      <td>
        <p>The tarball that represents a container layer</p>
      </td>
    </tr>
  </tbody>
</table>

<a name="container_layer_args"></a>
### Attributes


<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="container_layer.name">
      <td><code>name</code></td>
      <td>
        <p><code><a href="https://bazel.build/docs/build-ref.html#name">Name</a>; Required</code></p>
        <p>A unique name for this rule.</p>
      </td>
    </tr>
    <tr id="container_layer.data_path">
      <td><code>data_path</code></td>
      <td>
        <p><code>String; Optional; Default is ''</code></p>
        <p>The directory structure from the files is preserved inside the
layer but a prefix path determined by <code>data_path</code> is removed from the
directory structure. This path can be absolute from the workspace root if
starting with a <code>/</code> or relative to the rule's directory. A relative path
may start with "./" (or be ".") but cannot go up with "..". By default, the
<code>data_path</code> attribute is unused and all files are supposed to have no
prefix.</p>
      </td>
    </tr>
    <tr id="container_layer.debs">
      <td><code>debs</code></td>
      <td>
        <p><code>List of <a href="https://bazel.build/docs/build-ref.html#labels">labels</a>; Optional; Default is []</code></p>
        <p>A list of Debian packages that will be extracted into the layer.</p>
      </td>
    </tr>
    <tr id="container_layer.directory">
      <td><code>directory</code></td>
      <td>
        <p><code>String; Optional; Default is '/'</code></p>
        <p>The directory in which to expand the specified files, defaulting
to '/'. Only makes sense accompanying one of files/tars/debs.</p>
      </td>
    </tr>
    <tr id="container_layer.files">
      <td><code>files</code></td>
      <td>
        <p><code>List of <a href="https://bazel.build/docs/build-ref.html#labels">labels</a>; Optional; Default is []</code></p>
        <p>A list of files that should be included in the layer.</p>
      </td>
    </tr>
    <tr id="container_layer.mode">
      <td><code>mode</code></td>
      <td>
        <p><code>String; Optional; Default is '0555'</code></p>
        <p>Set the mode of files added by the <code>files</code> attribute.</p>
      </td>
    </tr>
    <tr id="container_layer.symlinks">
      <td><code>symlinks</code></td>
      <td>
        <p><code>Dictionary mapping strings to string; Optional; Default is {}</code></p>
        <p>Symlinks between files in the layer
<code>{ "/path/to/link": "/path/to/target" }</code></p>
      </td>
    </tr>
    <tr id="container_layer.tars">
      <td><code>tars</code></td>
      <td>
        <p><code>List of <a href="https://bazel.build/docs/build-ref.html#labels">labels</a>; Optional; Default is []</code></p>
        <p>A list of tar files whose content should be in the layer.</p>
      </td>
    </tr>
  </tbody>
</table>

<a name="container_layer_examples"></a>
### Examples

```python
load("@bazel_rules_container//container:layer.bzl", "container_layer")

filegroup(
    name = "nodejs_debs",
    srcs = [
        "nodejs.deb",
        "libgdbm3.deb",
        "perl.deb",
        "perl_modules.deb",
        "rlwrap.deb",
    ],
)

container_layer(
    name = "nodejs_files",
    debs = [":nodejs_debs"],
    symlinks = { "/usr/bin/node": "/usr/bin/nodejs" },
)
```
<a name="container_layer_debian_stretch_symlink_fix"></a>
## container_layer_debian_stretch_symlink_fix

<pre>
container_layer_debian_stretch_symlink_fix(<a href="#container_layer_debian_stretch_symlink_fix.name">name</a>, <a href="#container_layer_debian_stretch_symlink_fix.layer">layer</a>)
</pre>

Fix a layer so it works correctly on top of a Debian Stretch base image.

   Debian Stretch has symlinks from bin, lib, lib32, lib64, libx32 and sbin to
   /usr. Some deb files write directly to these symlink-ed folders which causes
   The symlink to be overridden.


<a name="container_layer_debian_stretch_symlink_fix_outputs"></a>
### Outputs


<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr>
      <td><code>%{name}.layer</code></td>
      <td>
        <p>The tarball that represents a container layer</p>
      </td>
    </tr>
  </tbody>
</table>

<a name="container_layer_debian_stretch_symlink_fix_args"></a>
### Attributes


<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="container_layer_debian_stretch_symlink_fix.name">
      <td><code>name</code></td>
      <td>
        <p><code><a href="https://bazel.build/docs/build-ref.html#name">Name</a>; Required</code></p>
        <p>A unique name for this rule.</p>
      </td>
    </tr>
    <tr id="container_layer_debian_stretch_symlink_fix.layer">
      <td><code>layer</code></td>
      <td>
        <p><code><a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; Required</code></p>
        <p>A container layer to fix.</p>
      </td>
    </tr>
  </tbody>
</table>

<a name="container_layer_debian_stretch_symlink_fix_examples"></a>
### Examples

```python
load("@bazel_rules_container//container:layer.bzl", "container_layer_symlink_fix")

container_layer_symlink_fix(
    name = "files_fixed",
    layer = ":files",
)
```
<a name="container_layer_from_tar"></a>
## container_layer_from_tar

<pre>
container_layer_from_tar(<a href="#container_layer_from_tar.name">name</a>, <a href="#container_layer_from_tar.tar">tar</a>)
</pre>

Uses an existing tarball as a layer in a container image.


<a name="container_layer_from_tar_outputs"></a>
### Outputs


<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr>
      <td><code>%{name}.layer</code></td>
      <td>
        <p>The tarball represented as a container layer</p>
      </td>
    </tr>
  </tbody>
</table>

<a name="container_layer_from_tar_args"></a>
### Attributes


<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="container_layer_from_tar.name">
      <td><code>name</code></td>
      <td>
        <p><code><a href="https://bazel.build/docs/build-ref.html#name">Name</a>; Required</code></p>
        <p>A unique name for this rule.</p>
      </td>
    </tr>
    <tr id="container_layer_from_tar.tar">
      <td><code>tar</code></td>
      <td>
        <p><code><a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; Required</code></p>
        <p>A tar file that will be the layer.</p>
      </td>
    </tr>
  </tbody>
</table>

<a name="container_layer_from_tar_examples"></a>
### Examples

```python
load("@bazel_rules_container//container:layer.bzl", "container_layer_from_tar")

genrule(
  name = "jessie_tar",
  srcs = ["@debian_jessie//file"],
  outs = ["jessie_extracted.tar"],
  cmd = "cat $< | xzcat >$@",
)

container_layer_from_tar(
    name = "jessie",
    tar = ":jessie_tar",
)
```

<!---
Documentation generated by Skydoc
-->
<h1>Open Container Initiative Image Format support for Bazel</h1>


<nav class="toc">
  <h2><a href="#overview">Overview</a></h2>
  <h2>Rules</h2>
  <ul>
    <li><a href="#container_image">container_image</a></li>
  </ul>
</nav>
<hr>

<a name="overview"></a>
## Overview

These rules are used for building [OCI images](https://github.com/opencontainers/image-spec).

The `container_image` rule constructs a tarball which conforms to [v0.2.0](https://github.com/opencontainers/image-spec/blob/v0.2.0/serialization.md)
of the OCI Image Specification. Currently [Docker](https://docker.com) is the
only container runtime which is able to load these images.

Each image can contain multiple layers which can be created via the
`container_layer` rule.

<a name="container_image"></a>
## container_image

<pre>
container_image(<a href="#container_image.name">name</a>, <a href="#container_image.base">base</a>, <a href="#container_image.cmd">cmd</a>, <a href="#container_image.config_file">config_file</a>, <a href="#container_image.entrypoint">entrypoint</a>, <a href="#container_image.env">env</a>, <a href="#container_image.image_name">image_name</a>, <a href="#container_image.image_tag">image_tag</a>, <a href="#container_image.labels">labels</a>, <a href="#container_image.layers">layers</a>, <a href="#container_image.ports">ports</a>, <a href="#container_image.user">user</a>, <a href="#container_image.volumes">volumes</a>, <a href="#container_image.workdir">workdir</a>)
</pre>

Creates an image which conforms to the OCI Image Serialization specification.

More information on the specification is available at
https://github.com/opencontainers/image-spec/blob/v0.2.0/serialization.md.

By default this rule builds partial images which can be loaded into a container
runtime via `bazel run`. To build a standalone image build with .tar at the end
if the name. The resulting tarball is compatible with `docker load` and has the
structure:
```
{image-config-sha256}:
  {layer-sha256}.tar
{image-config-sha256}.json
...
manifest.json
```


<a name="container_image_outputs"></a>
### Outputs


<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr>
      <td><code>%{name}.tar</code></td>
      <td>
        <p>A container image that contains all partial images which can be loaded
standalone by the container runtime.</p>
      </td>
    </tr>
    <tr>
      <td><code>%{name}.partial.tar</code></td>
      <td>
        <p>A partial container image that contains no parent images. Used when
running the rule to only load changed images into the container runtime.</p>
      </td>
    </tr>
  </tbody>
</table>

<a name="container_image_args"></a>
### Attributes


<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="container_image.name">
      <td><code>name</code></td>
      <td>
        <p><code><a href="https://bazel.build/docs/build-ref.html#name">Name</a>; Required</code></p>
        <p>A unique name for this rule.</p>
      </td>
    </tr>
    <tr id="container_image.base">
      <td><code>base</code></td>
      <td>
        <p><code><a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; Optional</code></p>
        <p>The base container image on top of which this image will built upon,
equivalent to FROM in a Dockerfile.</p>
      </td>
    </tr>
    <tr id="container_image.cmd">
      <td><code>cmd</code></td>
      <td>
        <p><code>List of strings; Optional; Default is []</code></p>
        <p>A command to execute when the image is run.</p>
      </td>
    </tr>
    <tr id="container_image.config_file">
      <td><code>config_file</code></td>
      <td>
        <p><code><a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; Optional</code></p>
        <p>Use an existing container configuration file.</p>
      </td>
    </tr>
    <tr id="container_image.entrypoint">
      <td><code>entrypoint</code></td>
      <td>
        <p><code>List of strings; Optional; Default is []</code></p>
        <p>The entrypoint of the command when the image is run.</p>
      </td>
    </tr>
    <tr id="container_image.env">
      <td><code>env</code></td>
      <td>
        <p><code>Dictionary mapping strings to string; Optional; Default is {}</code></p>
        <p>Dictionary from environment variable names to their values when running
the container. <code>env = { "FOO": "bar", ... }</code></p>
      </td>
    </tr>
    <tr id="container_image.image_name">
      <td><code>image_name</code></td>
      <td>
        <p><code>String; Optional; Default is ''</code></p>
        <p>The name of the image which is used when it is loaded into a
container runtime. If not provided it will default to
<code>bazel/package_name</code>.</p>
      </td>
    </tr>
    <tr id="container_image.image_tag">
      <td><code>image_tag</code></td>
      <td>
        <p><code>String; Optional; Default is ''</code></p>
        <p>The tag applied to the image when it is loaded into a container
runtime. If not provided it will default to <code>target</code>.</p>
      </td>
    </tr>
    <tr id="container_image.labels">
      <td><code>labels</code></td>
      <td>
        <p><code>Dictionary mapping strings to string; Optional; Default is {}</code></p>
        <p>Dictionary from label names to their values.
<code>labels = { "foo": "bar", ... }</code></p>
      </td>
    </tr>
    <tr id="container_image.layers">
      <td><code>layers</code></td>
      <td>
        <p><code>List of <a href="https://bazel.build/docs/build-ref.html#labels">labels</a>; Optional; Default is []</code></p>
        <p>List of layers created by <code>container_layer</code> that make up this image.</p>
      </td>
    </tr>
    <tr id="container_image.ports">
      <td><code>ports</code></td>
      <td>
        <p><code>List of strings; Optional; Default is []</code></p>
        <p>List of ports to expose.</p>
      </td>
    </tr>
    <tr id="container_image.user">
      <td><code>user</code></td>
      <td>
        <p><code>String; Optional; Default is ''</code></p>
        <p>The user that the image should run as. Because building the image never
happens inside a container, this user does not affect the other actions
(e.g., adding files).</p>
      </td>
    </tr>
    <tr id="container_image.volumes">
      <td><code>volumes</code></td>
      <td>
        <p><code>List of strings; Optional; Default is []</code></p>
        <p>List of volumes to mount.</p>
      </td>
    </tr>
    <tr id="container_image.workdir">
      <td><code>workdir</code></td>
      <td>
        <p><code>String; Optional; Default is ''</code></p>
        <p>Initial working directory when running the container. Because
building the image never happens inside a container, this working directory
does not affect the other actions (e.g., adding files).</p>
      </td>
    </tr>
  </tbody>
</table>

<a name="container_image_examples"></a>
### Examples

```python
load("@bazel_rules_container//container:layer.bzl", "container_layer")
load("@bazel_rules_container//container:image.bzl", "container_image")

container_layer(
    name = "jessie_layer",
    tars = [":jessie_tar"],
)
container_image(
    name = "jessie",
    layers = [":jessie_layer"],
)

# Using the `nodejs_files` layer from the `container_layer` example
container_image(
    name = "nodejs",
    layers = [":nodejs_files"],
)
```

<!---
Documentation generated by Skydoc
-->
<h1>Container testing</h1>


<nav class="toc">
  <h2><a href="#overview">Overview</a></h2>
  <h2>Rules</h2>
  <ul>
    <li><a href="#container_test">container_test</a></li>
  </ul>
</nav>
<hr>

<a name="overview"></a>
## Overview

Based on Jsonnet jsonnet_to_json_test

<a name="container_test"></a>
## container_test

<pre>
container_test(<a href="#container_test.name">name</a>, <a href="#container_test.daemon">daemon</a>, <a href="#container_test.env">env</a>, <a href="#container_test.error">error</a>, <a href="#container_test.files">files</a>, <a href="#container_test.golden">golden</a>, <a href="#container_test.image">image</a>, <a href="#container_test.mem_limit">mem_limit</a>, <a href="#container_test.options">options</a>, <a href="#container_test.read_only">read_only</a>, <a href="#container_test.regex">regex</a>, <a href="#container_test.test">test</a>, <a href="#container_test.tmpfs_directories">tmpfs_directories</a>, <a href="#container_test.volume_files">volume_files</a>, <a href="#container_test.volume_mounts">volume_mounts</a>)
</pre>

Experimental container testing.

Does not work with sandboxing enabled.


<a name="container_test_args"></a>
### Attributes


<table class="params-table">
  <colgroup>
    <col class="col-param" />
    <col class="col-description" />
  </colgroup>
  <tbody>
    <tr id="container_test.name">
      <td><code>name</code></td>
      <td>
        <p><code><a href="https://bazel.build/docs/build-ref.html#name">Name</a>; Required</code></p>
        <p>A unique name for this rule.</p>
      </td>
    </tr>
    <tr id="container_test.daemon">
      <td><code>daemon</code></td>
      <td>
        <p><code>Boolean; Optional; Default is False</code></p>
        <p>Whether to run the container as a daemon or execute the test by
running it as the container command.</p>
      </td>
    </tr>
    <tr id="container_test.env">
      <td><code>env</code></td>
      <td>
        <p><code>Dictionary mapping strings to string; Optional; Default is {}</code></p>
        <p>Dictionary from environment variable names to their values when running
the container. <code>env = { "FOO": "bar", ... }</code></p>
      </td>
    </tr>
    <tr id="container_test.error">
      <td><code>error</code></td>
      <td>
        <p><code>Integer; Optional; Default is 0</code></p>
        <p>The expected error code.</p>
      </td>
    </tr>
    <tr id="container_test.files">
      <td><code>files</code></td>
      <td>
        <p><code>List of <a href="https://bazel.build/docs/build-ref.html#labels">labels</a>; Optional; Default is []</code></p>
        <p>Any files that the test script might require.</p>
      </td>
    </tr>
    <tr id="container_test.golden">
      <td><code>golden</code></td>
      <td>
        <p><code><a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; Optional</code></p>
        <p>The expected output.</p>
      </td>
    </tr>
    <tr id="container_test.image">
      <td><code>image</code></td>
      <td>
        <p><code><a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; Optional</code></p>
        <p>The image to run tests on.</p>
      </td>
    </tr>
    <tr id="container_test.mem_limit">
      <td><code>mem_limit</code></td>
      <td>
        <p><code>String; Optional; Default is ''</code></p>
        <p>Memory limit to add to the container.</p>
      </td>
    </tr>
    <tr id="container_test.options">
      <td><code>options</code></td>
      <td>
        <p><code>List of strings; Optional; Default is []</code></p>
        <p>Additional options to pass to the container.</p>
      </td>
    </tr>
    <tr id="container_test.read_only">
      <td><code>read_only</code></td>
      <td>
        <p><code>Boolean; Optional; Default is True</code></p>
        
      </td>
    </tr>
    <tr id="container_test.regex">
      <td><code>regex</code></td>
      <td>
        <p><code>Boolean; Optional; Default is False</code></p>
        <p>Set to 1 if <code>golden</code> contains a regex to match against the output.</p>
      </td>
    </tr>
    <tr id="container_test.test">
      <td><code>test</code></td>
      <td>
        <p><code><a href="https://bazel.build/docs/build-ref.html#labels">Label</a>; Optional</code></p>
        <p>Test script to run.</p>
      </td>
    </tr>
    <tr id="container_test.tmpfs_directories">
      <td><code>tmpfs_directories</code></td>
      <td>
        <p><code>List of strings; Optional; Default is []</code></p>
        
      </td>
    </tr>
    <tr id="container_test.volume_files">
      <td><code>volume_files</code></td>
      <td>
        <p><code>List of <a href="https://bazel.build/docs/build-ref.html#labels">labels</a>; Optional; Default is []</code></p>
        <p>List of files to mount.</p>
      </td>
    </tr>
    <tr id="container_test.volume_mounts">
      <td><code>volume_mounts</code></td>
      <td>
        <p><code>List of strings; Optional; Default is []</code></p>
        <p>List of mount points that match <code>volume_mounts</code>.</p>
      </td>
    </tr>
  </tbody>
</table>

<a name="container_test_examples"></a>
### Examples

```python
load("@bazel_rules_container//container:test.bzl", "container_test")

container_test(
    name = "nodejs",
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
