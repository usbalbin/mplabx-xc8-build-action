#!/bin/bash

set -x -e

MPLABX_VERSION=$1
XC8_VERSION=$2
PROJECT=$3
CONFIGS=$4
MPLAB_DOWNLOAD_URL=$5
DEVICE_PACK=$6
DEVICE_PACK_VERSION=$7

WD=$(pwd)

echo $HOME

echo "Building project $PROJECT with MPLAB X v$MPLABX_VERSION and XC8 v$XC8_VERSION"

# Install the dependencies
# See https://microchipdeveloper.com/install:mplabx-lin64
dpkg --add-architecture i386 && \
  apt-get update && \
  apt-get install -y libc6:i386 libx11-6:i386 libxext6:i386 libstdc++6:i386 libexpat1:i386 libusb-1.0-0-dev wget sudo make default-jre && \
  apt-get clean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# Download and install XC8
wget -nv -O /tmp/xc8 "https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/xc8-v${XC8_VERSION}-full-install-linux-x64-installer.run" && \
  chmod +x /tmp/xc8 && \
  /tmp/xc8 --mode unattended --unattendedmodeui none --netservername localhost --LicenseType FreeMode --prefix "/opt/microchip/xc8/v${XC8_VERSION}" && \
  rm /tmp/xc8

# Download and install MPLAB X
wget -nv -O /tmp/mplabx "$MPLAB_DOWNLOAD_URL" &&\
  cd /tmp && \
  tar -xf mplabx && \
  rm mplabx && \
  mv "MPLABX-v${MPLABX_VERSION}-linux-installer.sh" mplabx && \
  sudo ./mplabx --nox11 -- --unattendedmodeui none --mode unattended --ipe 0 --collectInfo 0 --installdir /opt/mplabx --16bitmcu 0 --32bitmcu 0 --othermcu 0 && \
  rm mplabx

cd $WD

sudo chmod +x /opt/mplabx/mplab_platform/bin/packmanagercli.sh
#Look for '<pack name="([\.a-zA-Z\-_\d ])*" vendor="([\.a-zA-Z\-_\d ]*)Microchip" version="([\.a-zA-Z\-_\d ]*)"/>' in nbproject/configurations.xml
sudo /opt/mplabx/mplab_platform/bin/packmanagercli.sh --install-pack $DEVICE_PACK --version $DEVICE_PACK_VERSION --vendor Microchip

# Build
/opt/mplabx/mplab_platform/bin/prjMakefilesGenerator.sh -v "$(pwd)/$PROJECT" || exit 1

for CONFIG in $CONFIGS; do
    echo make -C "$PROJECT" CONF="$CONFIG" build
    make -C "$PROJECT" CONF="$CONFIG" build || exit 2
done
