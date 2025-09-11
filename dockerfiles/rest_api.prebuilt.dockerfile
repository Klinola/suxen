# Dockerfile for pre-built bento-rest-api binary
# Usage: docker build -f dockerfiles/rest_api.prebuilt.dockerfile --build-arg BINARY_URL=<url> -t bento-rest-api:prebuilt .

# Use Ubuntu 24.04 for GLIBC 2.38+ compatibility
FROM ubuntu:24.04

ARG BINARY_URL

ENV http_proxy=http://172.17.0.1:8080 \
    https_proxy=http://172.17.0.1:8080 \
    HTTP_PROXY=http://172.17.0.1:8080 \
    HTTPS_PROXY=http://172.17.0.1:8080 \
    no_proxy=localhost,127.0.0.1,::1 \
    NO_PROXY=localhost,127.0.0.1,::1

# Install runtime dependencies matching non-prebuilt version
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        openssl \
        tar && \
    rm -rf /var/lib/apt/lists/*

# Download and extract bento bundle tar.gz
RUN if [ -z "$BINARY_URL" ]; then echo "ERROR: BINARY_URL is required" && exit 1; fi && \
    mkdir -p /app && \
    curl -L -o /tmp/bento-bundle.tar.gz "$BINARY_URL" && \
    tar -xzf /tmp/bento-bundle.tar.gz -C /tmp && \
    mv /tmp/bento-bundle/bento-rest-api /app/rest_api && \
    rm -rf /tmp/*

WORKDIR /app
ENTRYPOINT ["/app/rest_api"]