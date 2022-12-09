#!/bin/bash

#### SCRIPT TO MOUNT/UNMOUNT ENCRYPTED VOLUME ####
# Created: May, 2022
# Creator: Leandro Schabarum
# Contact: leandroschabarum.98@gmail.com
##################################################
# Exit codes:
# 0 - Successfully executed script
# 1 - Execution failed (Generic)
# 2 - Missing required dependencies
##################################################

Help() {
	cat <<- EOF >&1
	$(basename "$0") DIR [OPTIONS]
	Script for mounting and unmounting encrypted devices.

	-m <path>    (optional)  Open and mount LUKS encrypted device.
	-u <path>    (optional)  Unmount and close LUKS encrypted device.
	-h           (optional)  Displays help information.
	EOF
}

Dependencies() {
	local DEPENDENCY

	for DEPENDENCY in "$@"
	do
		if ! command -v "$DEPENDENCY" > /dev/null 2>&1
		then
			echo "CRITICAL: Missing '$DEPENDENCY' - Install it first!" >&2
			exit 2
		fi
	done
}

# Ensure the required dependencies are installed
Dependencies "cryptsetup"

# Ensure valid values after processing input
if [[ -n "$1" && -d "$1" ]]
then
	MOUNT="$1"
	shift;
else
	echo "ERROR: Invalid directory argument [${1:-NULL}]" >&2
	exit 1
fi

while getopts 'm:u:h' OPT
do
	case "$OPT" in
		m )
			if [[ -e "${OPTARG}" ]]
			then
				DEV=${OPTARG}
				if cryptsetup open "${DEV}" "ext_luks_${DEV##*/}" --type luks
				then
					mount -t ext4 -o rw "/dev/mapper/ext_luks_${DEV##*/}" "${MOUNT}"

					echo "SUCCESS: Mounted ${DEV} [ext_luks_${DEV##*/}] to ${MOUNT}" >&1
					exit 0
				fi

				echo "ERROR: Unable to mount ${DEV} [ext_luks_${DEV##*/}] to ${MOUNT}" >&2
				exit 1
			else
				echo "ERROR: Invalid device path" >&2
				exit 1
			fi
			;;

		u )
			if [[ -e "${OPTARG}" ]]
			then
				DEV=${OPTARG}
				umount "${MOUNT}"

				if cryptsetup close "/dev/mapper/ext_luks_${DEV##*/}"
				then
					sleep 5
					echo "offline" > "/sys/block/${DEV##*/}/device/state"
					echo "1" > "/sys/block/${DEV##*/}/device/delete"

					echo "SUCCESS: Unmounted and ejected ${DEV} [ext_luks_${DEV##*/}] from ${MOUNT}" >&1
					exit 0
				fi

				echo "WARN: Unable to properly unmount and eject ${DEV} [ext_luks_${DEV##*/}] from ${MOUNT}" >&1
				exit 1
			else
				echo "ERROR: Invalid device path" >&2
				exit 1
			fi
			;;

		h ) # Displays help information
			Help
			exit 0
			;;

		\? ) # Invalid option
			echo "ERROR: Invalid option" >&2
			Help
			exit 1
		;;
	esac
done
