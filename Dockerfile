# syntax=docker/dockerfile:1.7
FROM --platform=$TARGETPLATFORM amazonlinux

ARG TARGETARCH
ARG DUCKDB_VERSION=1.5.1
ARG PLANETILER_VERSION=0.10.2
ARG S5CMD_VERSION=2.3.0

# Download Java 22+ for single-file .java Planetiler profiles

RUN yum update -y && yum install -y java-22-amazon-corretto-headless tar unzip && yum clean all

# Install s5cmd for S3 operations (parallel transfers; prefer over AWS CLI for data movement)
RUN S5CMD_ARCH=$([ "${TARGETARCH}" = "arm64" ] && echo "Linux-arm64" || echo "Linux-64bit") && \
    curl -fsSL "https://github.com/peak/s5cmd/releases/download/v${S5CMD_VERSION}/s5cmd_${S5CMD_VERSION}_${S5CMD_ARCH}.tar.gz" \
        -o s5cmd.tar.gz && \
    tar -xzf s5cmd.tar.gz s5cmd && \
    mv s5cmd /usr/local/bin/s5cmd && \
    rm s5cmd.tar.gz

# Download planetiler JAR
RUN curl -L "https://github.com/onthegomap/planetiler/releases/download/v${PLANETILER_VERSION}/planetiler.jar" -o planetiler.jar

# Download and install duckdb for bbox.sh filtering of GeoParquet
RUN curl -L "https://github.com/duckdb/duckdb/releases/download/v${DUCKDB_VERSION}/duckdb_cli-linux-${TARGETARCH}.zip" -o duckdb_cli-linux.zip && unzip duckdb_cli-linux.zip -d /usr/local/bin/ && rm duckdb_cli-linux.zip

# Copy profiles
COPY profiles /profiles

# Copy scripts
COPY run.sh /run.sh
COPY bbox.sh /bbox.sh

ENTRYPOINT ["bash", "/run.sh"]
