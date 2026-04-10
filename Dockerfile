# syntax=docker/dockerfile:1.7
FROM debian:bookworm-slim

ARG TARGETARCH
ARG DUCKDB_VERSION=1.5.1
ARG JAVA_VERSION=22
ARG PLANETILER_VERSION=0.10.2
ARG S5CMD_VERSION=2.3.0

LABEL org.opencontainers.image.title="overture-tiles"

# Install all tools in a single layer so build-only packages can be purged without
# bloating intermediate layers. libsqlite3-0 and zlib1g are listed explicitly so
# apt marks them as manually installed and --auto-remove does not pull them out.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg2 \
        unzip \
    && rm -rf /var/lib/apt/lists/* && \
    \
    # Install s5cmd for S3 operations (parallel transfers; prefer over AWS CLI for data movement)
    S5CMD_ARCH=$([ "${TARGETARCH}" = "arm64" ] && echo "Linux-arm64" || echo "Linux-64bit") && \
    curl -fsSL "https://github.com/peak/s5cmd/releases/download/v${S5CMD_VERSION}/s5cmd_${S5CMD_VERSION}_${S5CMD_ARCH}.tar.gz" \
        -o s5cmd.tar.gz && \
    tar -xzf s5cmd.tar.gz s5cmd && \
    mv s5cmd /usr/local/bin/s5cmd && \
    rm s5cmd.tar.gz && \
    \
    # Install DuckDB CLI (bbox filtering of GeoParquet)
    curl -fsSL "https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_VERSION}/duckdb_cli-linux-${TARGETARCH}.zip" \
        -o duckdb_cli.zip && \
    unzip duckdb_cli.zip -d /usr/local/bin/ && \
    rm duckdb_cli.zip && \
    \
    # Install Java via Amazon Corretto (for Planetiler single-file .java profiles)
    curl -fsSL https://apt.corretto.aws/corretto.key | \
        gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" \
        > /etc/apt/sources.list.d/corretto.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends java-${JAVA_VERSION}-amazon-corretto-jdk && \
    rm -rf /var/lib/apt/lists/* && \
    \
    # Download Planetiler JAR (tile generation)
    curl -fsSL "https://github.com/onthegomap/planetiler/releases/download/v${PLANETILER_VERSION}/planetiler.jar" \
        -o /planetiler.jar && \
    \
    # Purge build-only tools; ca-certificates is retained for runtime TLS
    apt-get purge -y --auto-remove curl gnupg2 unzip && \
    apt-get clean

# Copy profiles
COPY profiles /profiles

# Copy scripts
COPY run.sh /run.sh
COPY bbox.sh /bbox.sh

ENTRYPOINT ["bash", "/run.sh"]
