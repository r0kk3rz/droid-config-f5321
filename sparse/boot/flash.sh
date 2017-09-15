#!/bin/bash

# Contact: Matti Kosola <matti.kosola@jollamobile.com>
#
#
# Copyright (c) 2017, Jolla Ltd.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# * Neither the name of the <organization> nor the
# names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

set -e

function check_fastboot {
  FASTBOOT_BIN_NAME=$1
  if [ -f "$FASTBOOT_BIN_NAME" ]; then
    chmod 755 $FASTBOOT_BIN_NAME
    # Ensure that the binary that is found can be executed fine
    if ./$FASTBOOT_BIN_NAME help &>/dev/null; then
      FASTBOOT_BIN_PATH="./"
      return 0
    fi
  fi
  return 1
}

BLOBS=$(ls -1 SW_binaries_for_Xperia_AOSP_*_loire.zip | tail -n1)

if [ ! -f "$BLOBS" ]; then
  echo "Please download Sony Xperia X Software binaries for AOSP Marshmallow (Android 6.0.1) from"
  echo "https://developer.sonymobile.com/downloads/tool/software-binaries-for-aosp-marshmallow-6-0-1-loire/"
  echo "and place the file in this directory ($(pwd))"
  exit 1
fi

MAKE_EXT4FS=make_ext4fs

if [ ! -f "$MAKE_EXT4FS" ]; then
  echo "Please download the '$MAKE_EXT4FS' binary tool supplied by Jolla into this directory"
  echo "or build one yourself:"
  echo "git clone https://android.googlesource.com/platform/system/extras"
  echo "cd extras/ext4_utils"
  echo "git checkout 67bf7cb2c7487b2a93af8e2d9903842e8fe51f69 -b no-android-deps"
  echo "gcc [^se]*.c sha1.c sparse_crc32.c ext4_utils.c extent.c -o $MAKE_EXT4FS -lz"
  echo "cp $MAKE_EXT4FS $(pwd)"
  echo "cd $(pwd)"
  exit 1
fi

# Do not need root for fastboot on Mac OS X
if [ "$(uname)" != "Darwin" -a $(id -u) -ne 0 ]; then
  exec sudo -E bash $0
fi

UNAME=$(uname)
OS_VERSION=

case $UNAME in
  Linux)
    echo "Detected Linux"
    ;;
  Darwin)
    IFS='.' read -r major minor patch <<< $(sw_vers -productVersion)
    OS_VERSION=$major-$minor
    echo "Detected Mac OS X - Version: $OS_VERSION"
    ;;
  *)
    echo "Failed to detect operating system!"
    exit 1
    ;;
esac

VENDORIDLIST=(
"0fce"
)

echo "Searching device to flash.."
IFS=$'\n'
if [ "$UNAME" = "Darwin" ]; then
  # Mac OS X: Use System Profiler, get only the Vendor IDs and
  # append a colon at the end to make the lsusb-specific grep
  # from below work the same way as on Linux.
  LSUSB=( $(system_profiler SPUSBDataType | \
      grep -o 'Vendor ID: [x0-9a-f]*' | \
      sed -e 's/$/:/') )
else
  # Linux
  LSUSB=( $(lsusb) )
fi
unset IFS

VENDORIDFOUND=

for USB in "${LSUSB[@]}"; do
  for VENDORID in ${VENDORIDLIST[@]}; do
    # : after vendor id is to make sure we don't select based on product id.
    if [[ "$USB" =~ $VENDORID: ]]; then
      echo "Found device with vendor id '$VENDORID': $USB"
      VENDORIDFOUND=$VENDORID
    fi
  done
done

if [ -z $VENDORIDFOUND ]; then
  echo "No device that can be flashed found. Please connect device to fastboot mode before running this script."
  exit 1
fi

FASTBOOT_BIN_PATH=
FASTBOOT_BIN_NAME=

if ! check_fastboot "fastboot-$UNAME-$OS_VERSION" ; then
  if ! check_fastboot "fastboot-$UNAME"; then
    # In case we didn't provide functional fastboot binary to the system
    # lets check that one is found from the system.
    if ! which fastboot &>/dev/null; then
      echo "No 'fastboot' found in \$PATH. To install, use:"
      echo ""
      echo "    Debian/Ubuntu/.deb distros:  apt-get install android-tools-fastboot"
      echo "    Fedora:  yum install android-tools"
      echo "    OS X:    brew install android-sdk"
      echo ""
      exit 1
    else
      FASTBOOT_BIN_NAME=fastboot
    fi
  fi
fi

FASTBOOTCMD="${FASTBOOT_BIN_PATH}${FASTBOOT_BIN_NAME} -i 0x$VENDORIDFOUND $FASTBOOTEXTRAOPTS"

echo "Fastboot command: $FASTBOOTCMD"

FLASHCMD="$FASTBOOTCMD flash"

if [ -z ${BINARY_PATH} ]; then
  BINARY_PATH=./
fi

if [ -z ${SAILFISH_IMAGE_PATH} ]; then
  SAILFISH_IMAGE_PATH=./
fi

IMAGES=(
"boot ${SAILFISH_IMAGE_PATH}hybris-boot.img"
)

for IMAGE in "${IMAGES[@]}"; do
  read partition ifile <<< $IMAGE
  if [ ! -e ${ifile} ]; then
    echo "Image binary missing: ${ifile}."
    exit 1
  fi
done

for IMAGE in "${IMAGES[@]}"; do
  read partition ifile <<< $IMAGE
  echo "Flashing $partition partition.."
  $FLASHCMD $partition $ifile
done

# Flashing fimage to system partition
for x in fimage.img0*; do
  $FLASHCMD system $x
done

# Flashing to userdata for now..
for x in sailfish.img0*; do
  $FLASHCMD userdata $x
done

rm -rf tmp
mkdir tmp
unzip $BLOBS -d tmp
cp fw_bcmdhd.bin fw_bcmdhd_apsta.bin tmp/vendor/sony/loire-common/proprietary/vendor/firmware
chmod +x tmp/vendor/sony/loire-common/proprietary/vendor/bin/*
chmod +x ./$MAKE_EXT4FS
./$MAKE_EXT4FS -l 230M oem.img tmp/vendor/sony/loire-common/proprietary/vendor
rm -rf tmp
$FLASHCMD cache oem.img

echo "Flashing completed. Detach usb cable, press and hold the powerkey to reboot."

