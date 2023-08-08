#!/bin/bash

#
# Build railway tiles (using Planetiler)
#

# Stop on any error
set -e

# Declare constants
SHELL_EXEC="java -cp @/app/jib-classpath-file com.onthegomap.planetiler.Main"
DOCKER_EXEC="docker run --rm --user $UID:$GID -e JAVA_TOOL_OPTIONS="-Xmx4g" -v "$(pwd):/workspace" -w /workspace ghcr.io/onthegomap/planetiler:0.6-SNAPSHOT"
EXEC=$SHELL_EXEC

# Accept input variables from command flags
while getopts a:d: flag
do
    case "${flag}" in
        a) AREA=${OPTARG};;
        d) DOCKER=${OPTARG};;
    esac
done

# Fallback to environment vars or defaults for input variables
AREA="${AREA:=}" # Required. Example: greater_london
DOCKER="${DOCKER:=true}" # Default: True (i.e. Run with Docker)

# Validate input variables are set
[ -z "$AREA" ] && echo "AREA must be set, either as an environment variable or using -a command flag." && exit 1;

# Use Docker to execute script if $DOCKER is set
if [ "$DOCKER" == true ]
then
  EXEC=$DOCKER_EXEC
fi

echo "* Download OSM data & extract railway *ways* with *Planetiler*..."
$EXEC generate-custom \
--download \
--schema=config/railways.yml \
--area=$AREA \
--output="data/$AREA.planetiler.mbtiles"
rm -fr data/tmp/feature.db

# Confirm completion
echo "* Build completed!"
