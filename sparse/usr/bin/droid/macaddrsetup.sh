#!/bin/bash

echo "macaddr: Setting wlan MAC address"
/system/bin/macaddrsetup /sys/devices/soc.0/bcmdhd_wlan.115/macaddr
ip link set wlan0 up
echo "macaddr: Done"

if [ -e "/data/misc/bluetooth/bluetooth_bdaddr" ]; then
	mkdir -p "/var/lib/bluetooth"
	chmod 0755 "/var/lib/bluetooth"
	addr="$(cat /data/misc/bluetooth/bluetooth_bdaddr)"
	if [ -e "/var/lib/bluetooth/board-address" ]; then
		if [ "$addr" != "$(cat /var/lib/bluetooth/board-address)" ]; then
			echo "macaddr: Updating bt MAC address"
			echo "$addr" > /var/lib/bluetooth/board-address
			echo "macaddr: Done"
		fi
	else
		echo "macaddr: Setting bt MAC address"
		echo "$addr" > /var/lib/bluetooth/board-address
		echo "macaddr: Done"
	fi
fi
