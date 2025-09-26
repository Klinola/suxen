# Dockerfile for pre-built bento-rest-api binary
# Usage: docker build -f dockerfiles/rest_api.prebuilt.dockerfile --build-arg BINARY_URL=<url> -t bento-rest-api:prebuilt .

# Use Ubuntu 24.04 for GLIBC 2.38+ compatibility
FROM ubuntu:24.04

ARG BINARY_URL

ARG http_proxy
ARG https_proxy
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG no_proxy
ARG NO_PROXY

ENV http_proxy=http://172.17.0.1:8080 \
    https_proxy=http://172.17.0.1:8080 \
    HTTP_PROXY=http://172.17.0.1:8080 \
    HTTPS_PROXY=http://172.17.0.1:8080 \
    no_proxy=$no_proxy \
    NO_PROXY=$NO_PROXY

# Install runtime dependencies matching non-prebuilt version
RUN apt-get update && \
    apt-get install -y openssl curl tar ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Download and extract bento bundle tar.gz
RUN if [ -z "$BINARY_URL" ]; then echo "ERROR: BINARY_URL is required" && exit 1; fi && \
    mkdir -p /app && \
    curl -L -x http://172.17.0.1:8080 -o /tmp/bento-bundle.tar.gz "$BINARY_URL" && \
    tar -xzf /tmp/bento-bundle.tar.gz -C /tmp && \
    mv /tmp/bento-bundle/bento-rest-api /app/rest_api && \
    rm -rf /tmp/*

WORKDIR /app
ENTRYPOINT ["/app/rest_api"]