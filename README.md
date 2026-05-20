> A pre-built image is available at `ghcr.io/overturemaps/overture-tiles:latest`

# Overture Tiles
Create tilesets from [Overture Maps](http://overturemaps.org) data.

## Overview
This project provides tools to create vector tilesets in PMTiles format from Overture Maps data using Planetiler.

A reusable Terraform/OpenTofu module to create tilesets on AWS is available at [OvertureMaps/terraform-aws-overture-tiles](https://github.com/OvertureMaps/terraform-aws-overture-tiles).

For detailed deployment instructions, see the [Overture Tiles documentation](https://docs.overturemaps.org/examples/overture-tiles/).

## Architecture
The tile generation pipeline follows a three-stage process:

1. **Download**: Fetches Overture Maps data from the official S3 release (specified via `RELEASE` environment variable). Optionally supports geographic filtering using bounding boxes (`BBOX` environment variable) for smaller regional extracts.

2. **Transform**: Processes the downloaded data into PMTiles format using theme-specific Planetiler profiles (see Profiles section below).

3. **Upload**: Publishes the generated PMTiles to a specified S3 bucket (`OUTPUT` environment variable).

This pipeline runs on **AWS Batch**, which provides on-demand, scalable compute resources for processing large geospatial datasets without maintaining dedicated infrastructure. Batch jobs automatically scale based on workload, handle compute provisioning and only incur costs during active tile generation.

## Environment Variables
The Docker container accepts the following environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `RELEASE` | Yes* | Overture Maps release version (e.g., `2025-11-19.0`). *Required unless `SOURCE_OVERRIDE` is set. |
| `OUTPUT` | Yes | S3 bucket path for uploading generated PMTiles |
| `THEME` | Yes | Theme to process (`base`, `transportation`, `buildings`, `addresses`, `places`, or `divisions`) |
| `BBOX` | No | Bounding box for regional extracts (format: `minLon,minLat,maxLon,maxLat`) |
| `S3_REGION` | No | S3 region for data access (defaults to `us-west-2`) |
| `SKIP_UPLOAD` | No | Set to `true` to skip S3 upload (useful for local testing) |

## Profiles
All six themes (`addresses`, `base`, `buildings`, `divisions`, `places`, `transportation`) are processed using Planetiler profiles. See [profiles/](profiles/) for details.

Currently, profiles are fixed within the Docker image. There are plans to support custom profiles in the future.

## Development

### Prerequisites
To work with this project locally, you'll need:
- **[Docker](https://docs.docker.com/get-docker/)** - For running the tile generation container
- **[AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)** - For deployment and S3 operations (optional for local testing)
- **[Just](https://github.com/casey/just)** - Command runner for development tasks (optional but recommended)

### Internal: Custom Data Source

For testing with custom or pre-release data, `SOURCE_OVERRIDE` can be set to a custom S3 path instead of `RELEASE`. The data must follow the standard Overture parquet layout (`theme=X/type=Y/*.parquet`) and include a `bbox` struct column. `BBOX` filtering is also supported when using `SOURCE_OVERRIDE`.

| Variable | Description |
|----------|-------------|
| `SOURCE_OVERRIDE` | Custom S3 path for input data. Overrides `RELEASE` if set. |

### Testing Locally
You can test the tile generation process locally using Docker. Set the `SKIP_UPLOAD` environment variable to `true` to skip the upload step.

Using the justfile (recommended):
```sh
just test-local places
```

Or manually with Docker:
```sh
docker build -t overture-tiles:latest .
docker run --rm --name overture-test \
    -v $(pwd):/data \
    -e RELEASE='<overture-release-version>' \
    -e OUTPUT='noop' \
    -e THEME='places' \
    -e BBOX='-122.5247,37.7081,-122.3569,37.8324' \
    -e SKIP_UPLOAD='true' \
    overture-tiles:latest
```

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md)  for details.