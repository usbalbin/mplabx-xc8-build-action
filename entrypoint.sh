#!/bin/bash

set -x -e

MPLABX_VERSION=$1
XC8_VERSION=$2
PROJECT=$3
CONFIG=$4

echo "Building project $PROJECT:$CONFIG with MPLAB X $MPLABX_VERSION and XC8 $MPLABX_VERSION"

# Install the dependencies
# See https://microchipdeveloper.com/install:mplabx-lin64
dpkg --add-architecture i386 && \
  apt-get update && \
  apt-get install -y libc6:i386 libx11-6:i386 libxext6:i386 libstdc++6:i386 libexpat1:i386 wget sudo make default-jre && \
  apt-get clean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# Download and install XC8
wget -nv -O /tmp/xc8 "https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/xc8-v${XC8_VERSION}-full-install-linux-x64-installer.run" && \
  chmod +x /tmp/xc8 && \
  /tmp/xc8 --mode unattended --unattendedmodeui none --netservername localhost --LicenseType FreeMode --prefix "/opt/microchip/xc8/v${XC8_VERSION}" && \
  rm /tmp/xc8

# Download and install MPLAB X
wget -nv -O /tmp/mplabx "https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/MPLABX-v${MPLABX_VERSION}-linux-installer.tar" &&\
  cd /tmp && \
  tar -xf mplabx && \
  rm mplabx && \
  mv "MPLABX-v${MPLABX_VERSION}-linux-installer.sh" mplabx && \
  sudo ./mplabx --nox11 -- --unattendedmodeui none --mode unattended --ipe 0 --collectInfo 0 --installdir /opt/mplabx --16bitmcu 0 --32bitmcu 0 --othermcu 0 && \
  rm mplabx

ls /opt

ls /opt/microchip/mplabx/v${MPLABX_VERSION}/mplab_platform/bin/prjMakefilesGenerator.sh

# Build
/opt/microchip/mplabx/v${MPLABX_VERSION}/mplab_platform/bin/prjMakefilesGenerator.sh "$PROJECT@$CONFIG" || exit 1
make -C "$1" CONF="$CONFIG" build || exit 2
