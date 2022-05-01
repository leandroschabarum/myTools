#!/bin/bash

reset="\\033[0m"
yellow="\\033[1;33m"
green="\\033[1;32m"
red="\\033[1;31m"

Help() {
	cat <<- EOF >&1
	$(basename "$0") <DIR> [OPTIONS]
	-m	Open and mount LUKS encrypted device
	-u	Unmount and close LUKS encrypted device
	-h	Displays help information
	EOF
}

if ! command -v cryptsetup > /dev/null 2>&1
then
        echo -e "${red}Missing cryptsetup, please install it first!${reset}" >&2
        exit 1
fi

if [[ -n "$1" && -d "$1" ]]
then
	MOUNT="$1"
	shift;
else
	echo -e "${yellow}Invalid directory argument [${1:-NULL}]${reset}" >&2
	exit 1
fi

while getopts ":m:u:h" option
do
	case "${option}" in
		m)
		if [[ -e "${OPTARG}" ]]
		then
			DEV=${OPTARG}
			if cryptsetup open "${DEV}" "ext_luks_${DEV##*/}" --type luks
			then
				mount -t ext4 -o rw "/dev/mapper/ext_luks_${DEV##*/}" "${MOUNT}"

				echo -e "${green}Mounted ${DEV} [ext_luks_${DEV##*/}] to ${MOUNT}${reset}"
				exit 0
			fi

			echo -e "${red}Unable to mount ${DEV} [ext_luks_${DEV##*/}] to ${MOUNT}${reset}"
			exit 1
		else
			echo -e "${red}Invalid device path${reset}" >&2
			exit 1
		fi
		;;
		
		u)
		if [[ -e "${OPTARG}" ]]
		then
			DEV=${OPTARG:?}
			umount "${MOUNT}"
			
			if cryptsetup close "/dev/mapper/ext_luks_${DEV##*/}"
			then
				sleep 5
				echo "offline" > "/sys/block/${DEV##*/}/device/state"
				echo "1" > "/sys/block/${DEV##*/}/device/delete"
			
				echo -e "${green}Unmounted and ejected ${DEV} [ext_luks_${DEV##*/}] from ${MOUNT}${reset}"
				exit 0
			fi

			echo -e "${yellow}Unable to properly unmount and eject ${DEV} [ext_luks_${DEV##*/}] from ${MOUNT}${reset}"
			exit 1
		else
			echo -e "${red}Invalid device path${reset}" >&2
			exit 1
		fi
		;;

		h) # Displays help information
		Help
		exit 0
		;;
		
		\?) # Invalid option
		echo -e "${yellow}ERROR: Invalid option${reset}" >&2
		Help
		exit 1
		;;
	esac
done
