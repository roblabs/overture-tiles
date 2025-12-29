#!/usr/bin/env bash

set -e
set -u
set -o pipefail

# Arguments from run.sh
RELEASE=$1
BBOX=$2
THEME=$3
OUTPUT_DIR=$4
OVERTURE_RELEASE_BUCKET=$5
OVERTURE_REGION=$6

# Parse bbox
IFS=',' read -r MIN_LON MIN_LAT MAX_LON MAX_LAT <<< "$BBOX"

# Get types for the theme
case $THEME in
    addresses)
        TYPES="address"
        ;;
    base)
        TYPES="bathymetry infrastructure land land_cover water"
        ;;
    buildings)
        TYPES="building building_part"
        ;;
    divisions)
        TYPES="division division_area division_boundary"
        ;;
    places)
        TYPES="place"
        ;;
    transportation)
        TYPES="connector segment"
        ;;
esac

# Process each type
for TYPE in $TYPES; do
    # Create output directory
    TYPE_DIR="$OUTPUT_DIR/theme=$THEME/type=$TYPE"
    mkdir -p "$TYPE_DIR"

    OUTPUT_FILE="$TYPE_DIR/filtered.parquet"
    S3_PATH="$OVERTURE_RELEASE_BUCKET/$RELEASE/theme=$THEME/type=$TYPE/*.parquet"

    # Run DuckDB query
    duckdb -c "
    INSTALL spatial;
    LOAD spatial;

    -- Configure for anonymous S3 access
    SET s3_region='$OVERTURE_REGION';
    SET s3_url_style='path';

    -- Query and filter data by bbox
    COPY (
        SELECT
            *
        FROM read_parquet('$S3_PATH', union_by_name=true, filename=true, hive_partitioning=false)
        WHERE bbox.xmin <= $MAX_LON
          AND bbox.xmax >= $MIN_LON
          AND bbox.ymin <= $MAX_LAT
          AND bbox.ymax >= $MIN_LAT
    ) TO '$OUTPUT_FILE';
    "

    # Check if file was created and has content
    if [ ! -f "$OUTPUT_FILE" ] || [ ! -s "$OUTPUT_FILE" ]; then
        echo "No features found in bbox for $THEME/$TYPE"
        rm -f "$OUTPUT_FILE"
    fi
done
