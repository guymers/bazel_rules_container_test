Start a local registry to proxy requests to Docker Hub:

    docker run -p 5000:5000 \
      -v $(pwd)/registry/config.yml:/config.yml:ro \
      registry:2 /config.yml

Build the container:

    bazel build //nodejs

Run the tests:

    bazel test //test/...
