#!/bin/bash

#
# Build railway tiles (using Osmium)
#

# Stop on any error
set -e

# Declare constants
SHELL_EXEC="bash"
DOCKER_EXEC="docker run --rm --user $UID:$GID -v "$(pwd):/workspace" -w /workspace zhibek/osm-toolbox:1.1.0"
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

echo "* Download OSM data for area..."
$EXEC osm-download -a "$AREA"

echo "* Extract railway *ways* with *Osmium*..."
$EXEC osm-filter \
-a "$AREA" \
-f w/railway \
-o data/tmp/railways.osm.pbf

$EXEC osm-filter \
-a "$AREA" \
-f n/railway=station,halt,tram_stop \
-o data/tmp/stations.osm.pbf

echo "* Convert OSM output to FlatGeoBuf using *ogr2ogr*..."
$EXEC osm-to-flatgeobuf \
-i data/tmp/railways.osm.pbf \
-o data/tmp/railways.fgb \
-l lines \
-c config/osmconf.ini
rm -f data/tmp/railways.osm.pbf

$EXEC osm-to-flatgeobuf \
-i data/tmp/stations.osm.pbf \
-o data/tmp/stations.fgb \
-l points \
-c config/osmconf.ini
rm -f data/tmp/stations.osm.pbf

echo "* Convert FlatGeoBuf to MBTiles using *Tippecanoe*..."
$EXEC flatgeobuf-to-mbtiles \
-i "-L railways:data/tmp/railways.fgb -L stations:data/tmp/stations.fgb" \
-o "data/$AREA.osmium.mbtiles"
rm -f data/tmp/railways.fgb data/tmp/stations.fgb

# Confirm completion
echo "* Build completed!"
