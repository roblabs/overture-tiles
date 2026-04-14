# syntax=docker/dockerfile:1.7
FROM --platform=$TARGETPLATFORM amazonlinux

ARG TARGETARCH

# Download Java 22+ for single-file .java Planetiler profiles

RUN yum update -y && yum install -y java-22-amazon-corretto-headless unzip && yum clean all

# Download and install aws cli for authenticated uploads to S3 buckets.

ARG ARCH=${TARGETARCH/arm64/aarch64}
ARG ARCH=${ARCH/amd64/x86_64}
RUN curl -L https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip -o awscliv2.zip && unzip awscliv2.zip && ./aws/install && rm awscliv2.zip && rm -r ./aws

# Download planetiler JAR
RUN curl -L https://github.com/onthegomap/planetiler/releases/download/v0.10.2/planetiler.jar -o planetiler.jar

# Download and install duckdb for bbox.sh filtering of GeoParquet
RUN curl -L https://github.com/duckdb/duckdb/releases/download/v1.5.1/duckdb_cli-linux-${TARGETARCH}.zip -o duckdb_cli-linux.zip && unzip duckdb_cli-linux.zip -d /usr/local/bin/ && rm duckdb_cli-linux.zip

# Copy profiles
COPY profiles /profiles

# Copy scripts
COPY run.sh /run.sh
COPY bbox.sh /bbox.sh

ENTRYPOINT ["bash","/run.sh"]