#!/usr/bin/env just --justfile

latest_release := `curl -s https://stac.overturemaps.org | jq -r '.latest'`
overture_bucket := 's3://overturemaps-us-west-2'

@_default:
    {{ just_executable() }} --list

# Run a local test of the Docker container with the city of San Francisco. It skips uploading the generated PMTiles
[arg('theme', pattern='base|transportation|buildings|addresses|places|divisions')]
[group('test')]
test-local theme='places':
    docker build -t overture-tiles:latest .
    -docker rm -f overture-test 2>/dev/null || true
    docker run --rm --name overture-test \
        -v $(pwd):/data \
        -e RELEASE='{{ latest_release }}' \
        -e OUTPUT='noop' \
        -e THEME='{{ theme }}' \
        -e BBOX='-122.5247,37.7081,-122.3569,37.8324' \
        -e SKIP_UPLOAD='true' \
        overture-tiles:latest
