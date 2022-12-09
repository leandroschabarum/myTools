#!/bin/bash

############ SCRIPT TO CLEAR CACHE ############
# Created: Mar, 2020
# Creator: Leandro Schabarum
# Contact: leandroschabarum.98@gmail.com
###############################################
# Exit codes:
# 0 - Successfully executed script
# 1 - Execution failed (Generic)
###############################################

Help() {
	cat <<- EOF >&1
	$(basename "$0") [OPTIONS]
	Utility script to clear memory cache.

	-p    (optional)  Clears only PageCache.
	-i    (optional)  Clears only Dentries and Inodes.
	-a    (optional)  Clears all PageCache, Dentries and Inodes.
	-h    (optional)  Displays help information.
	EOF
}

while getopts "ciah" OPT
do
	case "${OPT}" in
		c )
			FLAG=1
			;;
		i )
			FLAG=2
			;;
		a )
			FLAG=3
			;;
		h ) # Displays help information
			Help
			exit 0
			;;
		\? ) # Invalid option
			echo "ERROR: Invalid script option" >&2
			Help
			exit 1
			;;
	esac
done

# Ensure script is executed with root privileges
if [[ $(id -u) -ne 0 ]]
then
	echo "ERROR: Requires sudo privileges to run" >&2
	exit 1
fi

# Ensure default values after processing input
FLAG=${FLAG:?'ERROR: Missing cache type option'}

if [[ $FLAG -eq 1 || $FLAG -eq 2 || $FLAG -eq 3 ]]
then
	sync
	echo $FLAG > /proc/sys/vm/drop_caches
	echo "SUCCESS: Caches dropped" >&1
fi

exit 0
