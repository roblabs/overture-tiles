# syntax=docker/dockerfile:1.7
FROM --platform=$TARGETPLATFORM amazonlinux

ARG TARGETARCH

# Download tippecanoe deps and Java 22+ for single-file .java Planetiler profiles, for large themes.

RUN yum update -y && yum install -y tar make gzip gcc-c++ sqlite-devel zlib-devel java-22-amazon-corretto-headless && yum clean all

# Build tippecanoe for creating tilesets for small themes.

RUN curl -L https://github.com/felt/tippecanoe/archive/refs/tags/2.79.0.tar.gz | tar xz -C /opt/
WORKDIR /opt/tippecanoe-2.79.0

RUN make && make install

WORKDIR /
RUN rm -r /opt/tippecanoe-2.79.0

# download and install duckdb for reading Overture Parquet files.

RUN curl -L https://github.com/duckdb/duckdb/releases/download/v1.4.0/duckdb_cli-linux-${TARGETARCH}.zip -o duckdb_cli-linux.zip && unzip duckdb_cli-linux.zip -d /usr/local/bin/ && rm duckdb_cli-linux.zip

RUN duckdb -c "install httpfs; install spatial;"

# Download and install aws cli for authenticated uploads to S3 buckets.

ARG ARCH=${TARGETARCH/arm64/aarch64}
ARG ARCH=${ARCH/amd64/x86_64}

RUN curl -L https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip -o awscliv2.zip && unzip awscliv2.zip && ./aws/install && rm awscliv2.zip && rm -r ./aws

# Download planetiler JAR.

RUN curl -L https://github.com/onthegomap/planetiler/releases/download/v0.9.2/planetiler.jar -o planetiler.jar

# copy current scripts into image.

COPY scripts /scripts
COPY profiles /profiles
COPY run.sh /run.sh

ENTRYPOINT ["bash","/run.sh"]