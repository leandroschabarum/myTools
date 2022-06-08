#!/bin/bash

################ SCRIPT TO CLEAR CACHE ################
# Created: Mar, 2020                                  #
# Creator: Leandro Schabarum                          #
# Contact: leandroschabarum.98@gmail.com              #
#######################################################

Help() {
	cat <<- EOF >&1
	Utility to clear memory cache.
	$(basename "$0") [OPTIONS]
	-p	clears only PageCache
	-i	clears only Dentries and Inodes
	-a	clears all PageCache, Dentries and Inodes
	-h	displays help information
	EOF
}

while getopts ":c:i:a:h" opt
do
	case "${opt}" in
		c)
			FLAG=1
			;;
		i)
			FLAG=2
			;;
		a)
			FLAG=3
			;;
		h)
			Help
			exit 0
			;;
		\?)
			echo "Invalid option!"
			Help
			exit 1
			;;
	esac
done

if [[ $(id -u) -eq 0 ]]
then
	if [[ $FLAG -eq 1 || $FLAG -eq 2 || $FLAG -eq 3 ]]
	then
		sync
		echo $FLAG > /proc/sys/vm/drop_caches
		echo "Done"
	fi
else
	echo "Requires sudo privileges to run" && exit 1
fi

exit 0
