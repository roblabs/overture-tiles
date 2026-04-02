#!/usr/bin/env sh

# Update & install packages
sudo apt update -y
    # sudo apt install -y just  # https://github.com/casey/just  # TODO:  an old version of `just` is installed for somereason
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin

# ---

# PMTiles
# https://github.com/protomaps/go-pmtiles/releases
PMTILES_VERSION="1.30.1"
UNAME_KERNEL_NAME=$(uname -s)
UNAME_PROCESSOR_NAME=$(uname -m)
PROCESSOR=""
CURL_URL=""

# Match Kernel & Processor name for PMTiles
if [ $UNAME_PROCESSOR_NAME = "arm64" ]
then
  PROCESSOR="arm64"
elif [ $UNAME_PROCESSOR_NAME = "aarch64" ]
then
  PROCESSOR="arm64"
elif [ $UNAME_PROCESSOR_NAME = "x86_64" ]
then
  PROCESSOR="x86_64"
fi

CURL_URL="https://github.com/protomaps/go-pmtiles/releases/download/v${PMTILES_VERSION}/go-pmtiles_${PMTILES_VERSION}_${UNAME_KERNEL_NAME}_${PROCESSOR}.tar.gz"
echo $UNAME_KERNEL_NAME
echo $UNAME_PROCESSOR_NAME
echo $PROCESSOR
echo $CURL_URL


sudo mkdir -p /opt/pmtiles
sudo curl -L $CURL_URL | sudo tar xz -C /opt/pmtiles
sudo cp /opt/pmtiles/pmtiles /usr/local/bin
sudo chown root /usr/local/bin/pmtiles
sudo chgrp root /usr/local/bin/pmtiles
