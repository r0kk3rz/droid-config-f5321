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

UNAME=$(uname)

# Do not need root for fastboot on Mac OS X
if [ "$UNAME" != "Darwin" -a $(id -u) -ne 0 ]; then
  exec sudo -E bash $0
fi

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

PRODUCT="$($FASTBOOTCMD getvar product 2>&1 | head -n1 | cut -d ' ' -f2)"

if [ -z "$(echo $PRODUCT | grep -e "F5[13]2[12]")" ]; then
  echo; echo "This script is not meant for device $PRODUCT."
  echo Please connect the right device and try again.
  echo;
  exit 1;
fi

if [ "$($FASTBOOTCMD getvar secure 2>&1 | head -n1 | cut -d ' ' -f2 )" == "yes" ]; then
  echo; echo "This device has not been unlocked, but you need that for flashing."
  echo "Please go to https://developer.sonymobile.com/unlockbootloader/ and see instructions how to unlock your device."
  echo;
  exit 1;
fi

read -r VMAJOR VMINOR<<<$($FASTBOOTCMD getvar version-baseband 2>&1 | head -n1 | cut -d ' ' -f2 | cut -d '_' -f2 | cut -d '.' -f1,2 | tr . ' ')

if (( $VMAJOR < 34 || $VMAJOR == 34 && $VMINOR < 3 )); then
  echo; echo "Your Sony Android version ($VMAJOR.$VMINOR) on your device is too old,"
  echo "Please go to https://developer.sonymobile.com/open-devices/flash-tool/how-to-download-and-install-the-flash-tool/ and update your device."
  echo;
  exit 1;
fi

if [ -z ${BINARY_PATH} ]; then
  BINARY_PATH=./
fi

if [ -z ${SAILFISH_IMAGE_PATH} ]; then
  SAILFISH_IMAGE_PATH=./
fi

IMAGES=(
"boot ${SAILFISH_IMAGE_PATH}hybris-boot.img"
)

if [ "$UNAME" = "Darwin" ]; then
  # macOS doesn't have md5sum so lets use md5 there.
  while read -r line; do
    md5=$(echo $line | cut -d ' ' -f1)
    filename=$(echo $line | cut -d ' ' -f2)
    md5calc=$(md5 $filename | cut -d '=' -f2 | tr -d '[:space:]')
    if [ "$md5" != "$md5calc" ]; then
      echo; echo "md5 sum does not match on file: $filename ($md5 vs $md5calc). Please re-download the package again."
      echo;
      exit 1;
    fi
  done < md5.lst
else
  if [ "$(md5sum -c md5.lst --status;echo $?)" -eq "1" ]; then
    echo; echo "md5sum does not match, please download the package again."
    echo;
    exit 1;
  fi
fi

FLASHCMD="$FASTBOOTCMD flash"

for IMAGE in "${IMAGES[@]}"; do
  read partition ifile <<< $IMAGE
  if [ ! -e ${ifile} ]; then
    echo "Image binary missing: ${ifile}."
    exit 1
  fi
done

BLOBS=""
for b in $(ls -1 *_loire.img 2>/dev/null); do
  if [ -n "$BLOBS" ]; then
   echo; echo "More than one Sony Vendor image was found. Please remove any additional files."
   echo
   exit 1
  fi
  BLOBS=$b
done

if [ -z $BLOBS ]; then
  echo; echo The Sony Vendor partition image was not found in the current directory. Please
  echo download it from
  echo https://developer.sonymobile.com/downloads/software-binaries/software-binaries-for-aosp-marshmallow-android-6-0-1-kernel-3-10-loire/
  echo and unzip it into this directory.
  echo
  exit 1
fi

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

echo "Flashing oem partition.."
$FLASHCMD oem $BLOBS

echo
echo "Flashing completed."
echo
echo "Remove the USB cable and bootup the device by pressing powerkey."
echo
