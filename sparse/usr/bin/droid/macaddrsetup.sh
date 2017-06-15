#!/bin/sh

echo macaddr: Setting MAC address
/system/bin/macaddrsetup /sys/devices/soc.0/bcmdhd_wlan.115/macaddr
ip link set wlan0 up
echo macaddr: Done
