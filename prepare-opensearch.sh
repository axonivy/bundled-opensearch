#!/bin/bash

# This script is used to prepare the opensearch and configuration

# Get the opensearch version from parameter or use default version
if [ -z "$1" ]; then
  echo "No opensearch version specified, using default version"
  exit 1
else
  echo "Using opensearch version $1"
  OPENSEARCH_VERSION=$1
fi

# Check if zip and unzip are installed
if ! [ -x "$(command -v zip)" ]; then
  echo "Error: zip is not installed." >&2
  exit 1
fi

if ! [ -x "$(command -v unzip)" ]; then
  echo "Error: unzip is not installed." >&2
  exit 1
fi

OPENSEARCH_URL="https://artifacts.opensearch.org/releases/bundle/opensearch/$OPENSEARCH_VERSION/opensearch-$OPENSEARCH_VERSION-windows-x64.zip"
FOLDER="opensearch-$OPENSEARCH_VERSION"
ZIP_FILE="$FOLDER-downloaded.zip"

# Delete made zip if exists
rm -rf $FOLDER/*

# Download the opensearch if zip file does not exist
if [ ! -f $ZIP_FILE ]; then
  echo "Downloading opensearch"
  curl -L -o $FOLDER-downloaded.zip $OPENSEARCH_URL
fi

# Unzip the opensearch using unzip docker image
unzip $ZIP_FILE \
  -x "*/opensearch-windows-install.bat" \
  -x "*/manifest.yml" \
  -x "*/NOTICE.txt" \
  -x "*/LICENSE.txt" \
  -x "*/jdk/*" \
  -x "*/lib/tools/*" \
  -x "*/plugins/*" \
  -x "*/modules/ingest-geoip/*" \
  -x "*/modules/ingest-common/*" \
  -x "*/modules/ingest-user-agent/*" \
  -x "*/modules/parent-join/*" \
  -x "*/modules/repository-url/*" \
  -x "*/modules/reindex/*" \
  -x "*/modules/search-pipeline-common/*" \
  -x "*/modules/geo/*" \
  -x "*/modules/mapper-extras/*" \
  -x "*/config/opensearch-notifications/*" \
  -x "*/config/opensearch-notifications-core/*" \
  -x "*/config/opensearch-observability/*" \
  -x "*/config/opensearch-security/*" \
  -x "*/config/opensearch-reports-scheduler/*" \
  -x "*/bin/opensearch-plugin*" \
  -x "*/bin/opensearch-node*" \
  -x "*/bin/opensearch-service*" \
  -x "*/bin/opensearch-upgrade*" \
  -x "*/bin/opensearch-shard*" \
  -x "*/bin/opensearch-keystore*" \
  -x "*/bin/opensearch-cli*" \

echo "Make launcher executable"
chmod +x $FOLDER/bin/opensearch

# Replace log4j2.properties
cp log4j2.properties $FOLDER/config/

# Comment out -Xlog:gc. Stops opensearch from logging garbage collection
sed -i '/-Xlog:gc/ s/^/# /' $FOLDER/config/jvm.options

echo "Adding options to opensearch.yml"
echo "
cluster.routing.allocation.disk.threshold_enabled: true
cluster.routing.allocation.disk.watermark.flood_stage: 1gb
cluster.routing.allocation.disk.watermark.high: 2gb
cluster.routing.allocation.disk.watermark.low: 5gb
" >> $FOLDER/config/opensearch.yml

echo "Zipping opensearch"
cd $FOLDER
zip -r $FOLDER.zip *
mv $FOLDER.zip ..
cd ..

echo "Done preparing opensearch"
