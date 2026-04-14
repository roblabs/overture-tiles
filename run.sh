#!/usr/bin/env bash

set -e
set -u

OVERTURE_RELEASE_BUCKET="s3://overturemaps-us-west-2/release"
OVERTURE_REGION="us-west-2"

# Required environment variables
OUTPUT="${OUTPUT:?Error: OUTPUT environment variable is required}"
THEME="${THEME:?Error: THEME environment variable is required}"

# Source configuration (one must be set)
RELEASE="${RELEASE:-}"  # Overture release version (default source)
SOURCE_OVERRIDE="${SOURCE_OVERRIDE:-}"  # Optional: Override source with custom S3 path for custom data

# Optional environment variables
CUSTOM_PROFILE="${CUSTOM_PROFILE:-}"
CUSTOM_SCRIPT="${CUSTOM_SCRIPT:-}"
SKIP_UPLOAD="${SKIP_UPLOAD:-false}"
S3_REGION="${S3_REGION:-us-west-2}"  # S3 region for data access

# TODO: Implement custom profile/script support later
if [ -n "$CUSTOM_PROFILE" ] || [ -n "$CUSTOM_SCRIPT" ]; then
  # Should download custom profile/script and use it. Currently not implemented.
  echo "Error: Custom profile/script support not yet implemented"
  exit 1
fi

# Download input data from S3
if [ -n "$SOURCE_OVERRIDE" ]; then
  if [ -n "${BBOX:-}" ]; then
    echo "Downloading from override source: $SOURCE_OVERRIDE with bbox filter..."
    aws s3 sync --no-progress --region "$S3_REGION" "$SOURCE_OVERRIDE" /tmp/overture_source/theme=$THEME
    bash "$(dirname "$0")/bbox.sh" "" "$BBOX" "$THEME" /data "" "" /tmp/overture_source
  else
    echo "Downloading from override source: $SOURCE_OVERRIDE"
    aws s3 sync --no-progress --region "$S3_REGION" "$SOURCE_OVERRIDE" /data/theme=$THEME
  fi
elif [ -n "$RELEASE" ]; then
  # Official Overture release (supports bbox filtering)
  if [ -n "${BBOX:-}" ]; then
    echo "Downloading Overture release $RELEASE with bbox filter..."
    bash "$(dirname "$0")/bbox.sh" "$RELEASE" "$BBOX" "$THEME" /data "$OVERTURE_RELEASE_BUCKET" "$OVERTURE_REGION"
  else
    echo "Downloading from Overture release: $RELEASE"
    aws s3 sync --no-progress --region "$OVERTURE_REGION" --no-sign-request "$OVERTURE_RELEASE_BUCKET/$RELEASE/theme=$THEME" /data/theme=$THEME
  fi
else
  echo "Error: Either RELEASE or SOURCE_OVERRIDE environment variable must be provided"
  exit 1
fi

# Generate tiles based on theme
className="${THEME^}"
java -XX:MaxRAMPercentage=70 -cp planetiler.jar /profiles/$className.java --data=/data

if [ "$SKIP_UPLOAD" != "true" ]; then
  [[ "$OUTPUT" != */ ]] && OUTPUT="${OUTPUT}/"
  aws s3 cp --no-progress /data/$THEME.pmtiles "$OUTPUT"
fi