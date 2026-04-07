# syntax=docker/dockerfile:1.7
FROM debian:bookworm-slim

ARG TARGETARCH
ARG TIPPECANOE_VERSION=2.79.0
ARG DUCKDB_VERSION=1.4.3
ARG PLANETILER_VERSION=0.9.2
ARG S5CMD_VERSION=2.3.0

LABEL org.opencontainers.image.title="overture-tiles"

# Install all tools in a single layer so build-only packages can be purged without
# bloating intermediate layers. Runtime shared libs (libsqlite3-0, zlib1g) are
# retained by apt when the corresponding -dev packages are purged.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        g++ \
        gnupg2 \
        libsqlite3-dev \
        make \
        unzip \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/* && \
    \
    # Build tippecanoe (tile generation for small themes)
    curl -fsSL "https://github.com/felt/tippecanoe/archive/refs/tags/${TIPPECANOE_VERSION}.tar.gz" | \
        tar xz -C /opt/ && \
    make -C "/opt/tippecanoe-${TIPPECANOE_VERSION}" && \
    make -C "/opt/tippecanoe-${TIPPECANOE_VERSION}" install && \
    rm -rf "/opt/tippecanoe-${TIPPECANOE_VERSION}" && \
    \
    # Install DuckDB CLI (reads Overture Parquet files)
    curl -fsSL "https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_VERSION}/duckdb_cli-linux-${TARGETARCH}.zip" \
        -o duckdb_cli.zip && \
    unzip duckdb_cli.zip -d /usr/local/bin/ && \
    rm duckdb_cli.zip && \
    \
    # Install s5cmd for S3 operations (parallel transfers; prefer over AWS CLI for data movement)
    S5CMD_ARCH=$([ "${TARGETARCH}" = "arm64" ] && echo "Linux-arm64" || echo "Linux-64bit") && \
    curl -fsSL "https://github.com/peak/s5cmd/releases/download/v${S5CMD_VERSION}/s5cmd_${S5CMD_VERSION}_${S5CMD_ARCH}.tar.gz" \
        -o s5cmd.tar.gz && \
    tar -xzf s5cmd.tar.gz s5cmd && \
    mv s5cmd /usr/local/bin/s5cmd && \
    rm s5cmd.tar.gz && \
    \
    # Install Java 22 via Amazon Corretto (for Planetiler single-file .java profiles, large themes)
    curl -fsSL https://apt.corretto.aws/corretto.key | \
        gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" \
        > /etc/apt/sources.list.d/corretto.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends java-22-amazon-corretto-headless && \
    rm -rf /var/lib/apt/lists/* && \
    \
    # Download Planetiler JAR (tile generation for large themes)
    curl -fsSL "https://github.com/onthegomap/planetiler/releases/download/v${PLANETILER_VERSION}/planetiler.jar" \
        -o /planetiler.jar && \
    \
    # Purge build-only tools; ca-certificates is retained for runtime TLS (duckdb httpfs, java, etc.)
    apt-get purge -y --auto-remove curl g++ gnupg2 libsqlite3-dev make unzip zlib1g-dev && \
    apt-get clean

# Pre-install DuckDB extensions
RUN duckdb -c "install httpfs; install spatial;"

# Copy default scripts and profiles
COPY scripts /scripts
COPY profiles /profiles
COPY run.sh /run.sh
COPY bbox.sh /bbox.sh

ENTRYPOINT ["bash", "/run.sh"]
