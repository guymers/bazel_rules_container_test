Build the container:

    bazel build //nodejs

Run the tests:

    bazel test //test/...

Push to a local Docker registry:

    bazel run //nodejs:push
