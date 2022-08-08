#!/bin/bash

BATTERY="BAT0"
FILESYSTEM="/sys/class/power_supply/${BATTERY:?'ERROR: Battery device not set'}"

STATUS="$(cat "${FILESYSTEM:?'ERROR: Filesystem dir not set'}/status")"
CHARGE="$(cat "${FILESYSTEM:?'ERROR: Filesystem dir not set'}/capacity")"

# Evaluates current host power state
case "${STATUS:?'WARN: Status not set'}" in
	Full)
		echo -e "[On AC power] Battery is fully charged."
		exit 0
		;;
	Charging)
		echo -e "[On AC power] Battery is charging ( ${CHARGE:-###}% )"
		exit 0
		;;
	Discharging)
		echo -e "[On Battery power] Battery is discharging ( ${CHARGE:-###}% )"
		exit 1
		;;
	*) # DEFAULT
		echo -e "[Action required] Unknown power state"
		exit 1
		;;
esac

