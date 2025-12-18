# Overture Tiles
Create tilesets from [Overture Maps](http://overturemaps.org) data.

## Overview
This project provides tools to create vector tilesets in PMTiles format from Overture Maps data using a combination of Planetiler and Tippecanoe. It includes AWS CDK constructs for deploying the necessary infrastructure to generate and host the tilesets.

> **Note**: Currently focused on AWS infrastructure (S3 & Batch), though the core processing runs in Docker containers

## Project Structure
The repository is organized into the following main components:
- **Infrastructure**: AWS CDK constructs to deploy the processing and hosting infrastructure.
- **Profiles**: Profiles for Planetiler to define how to process Overture Maps data into vector tiles.
- **Scripts**: Scripts are recipes to run Tippecanoe with specific configurations for generating PMTiles.

## Architecture
The tile generation pipeline follows a three-stage process:

1. **Download**: Fetches Overture Maps data from the official S3 release (specified via `RELEASE` environment variable). Optionally supports geographic filtering using bounding boxes (`BBOX` environment variable) for testing or smaller regional extracts.

2. **Transform**: Processes the downloaded data into PMTiles format using theme-specific profiles and scripts (see Profiles and Scripts section below).

3. **Upload**: Publishes the generated PMTiles to a specified S3 bucket (`OUTPUT` environment variable).

This pipeline runs on **AWS Batch**, which provides on-demand, scalable compute resources for processing large geospatial datasets without maintaining dedicated infrastructure. Batch jobs automatically scale based on workload, handle compute provisioning and only incur costs during active tile generation.

## Environment Variables
The Docker container accepts the following environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `RELEASE` | Yes | Overture Maps release version (e.g., `2025-11-19.0`) |
| `OUTPUT` | Yes | S3 bucket path for uploading generated PMTiles |
| `THEME` | Yes | Theme to process (`base`, `transportation`, `buildings`, `addresses`, `places`, or `divisions`) |
| `BBOX` | No | Bounding box for regional extracts (format: `minLon,minLat,maxLon,maxLat`) |
| `SKIP_UPLOAD` | No | Set to `true` to skip S3 upload (useful for local testing) |

## Profiles and Scripts
Profiles and scripts define how Overture Maps data is processed into vector tiles:
- **Planetiler profiles**: Used for `base`, `transportation`, `buildings`, and `addresses` themes. See [profiles/](profiles/) for details.
- **Tippecanoe scripts**: Used for `places` and `divisions` themes. See [scripts/](scripts/) for details.

Currently, these are fixed within the Docker image. There are ideas to support custom profiles and scripts in the future.

## Deploying to AWS
The CDK stack creates AWS Batch infrastructure for processing tiles at scale. Configure your S3 bucket and AWS account in [overture-tiles-cdk/bin/overture-tiles-cdk.ts](overture-tiles-cdk/bin/overture-tiles-cdk.ts), then deploy with standard CDK commands or use the [justfile](justfile) recipes.

For detailed deployment instructions, see the [Overture Tiles documentation](https://docs.overturemaps.org/examples/overture-tiles/).


## Testing Locally
It is possible to test the tile generation process locally using Docker. Just ensure that the `SKIP_UPLOAD` environment variable is set to `true` to skip the upload step. Example for generating tiles for San Francisco:

```sh
docker build -t overture-tiles:test .
docker run --name overture-test \
    -e RELEASE='2025-11-19.0' \
    -e OUTPUT='empty' \
    -e BBOX='-122.5247,37.7081,-122.3569,37.8324' \
    -e SKIP_UPLOAD='true' \
    overture-tiles:test
docker cp overture-test:/places.pmtiles ./sf-places.pmtiles
docker rm overture-test
```

> **Optional**: Mount a local directory as a volume (add `-v $(pwd):/output` to the `docker run` command) to access the generated PMTiles directly without needing `docker cp`.

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md)  for details.