#!/usr/bin/env just --justfile

cdk_dir := 'overture-tiles-cdk'
latest_release := '2025-11-19.0'
overture_bucket := 's3://overturemaps-us-west-2'

@_default:
    {{just_executable()}} --list

# Bootstrap the CDK environment
[group('setup')]
bootstrap-cdk:
    cd {{cdk_dir}} && npm install && npm run build

# Deploy the CDK stack
[group('setup')]
deploy-cdk bucket_name account region create_bucket='false':
    cd {{cdk_dir}} && npm run cdk deploy -- \
        -c bucketName={{bucket_name}} \
        -c account={{account}} \
        -c region={{region}} \
        -c createBucket={{create_bucket}}

# Destroy the CDK stack
[group('setup')]
destroy-cdk account region bucket_name='' delete_bucket='false':
    cd {{cdk_dir}} && npm run cdk destroy -- \
        -c bucketName={{bucket_name}} \
        -c account={{account}} \
        -c region={{region}} \
        -c deleteBucket={{delete_bucket}}

# Run a local test of the Docker container with the city of San Francisco. It skips uploading the generated PMTiles
[group('test')]
[arg('theme', pattern='base|transportation|buildings|addresses|places|divisions')]
test-local theme='places':
    docker build -t overture-tiles:latest .
    -docker rm -f overture-test 2>/dev/null || true
    docker run --rm --name overture-test \
        -v $(pwd):/data \
        -e RELEASE='{{latest_release}}' \
        -e OUTPUT='noop' \
        -e THEME='{{theme}}' \
        -e BBOX='-122.5247,37.7081,-122.3569,37.8324' \
        -e SKIP_UPLOAD='true' \
        overture-tiles:latest
