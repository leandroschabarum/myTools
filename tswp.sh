#!/bin/bash

################ SCRIPT TO CHECK AND CLEAR ################
################     LINUX SWAP MEMORY     ################
# Created: Mar, 2020                                      #
# Creator: Leandro Schabarum                              #
# Contact: leandroschabarum.98@gmail.com                  #
###########################################################

if [[ $(id -u) -eq 0 ]]
then
	MEMORY="$(free -b)"
	FREE_RAM="$(echo "$MEMORY" | grep 'Mem:' | awk '{print $7}')"
	USED_SWAP="$(echo "$MEMORY" | grep 'Swap:' | awk '{print $3}')"

	if [[ $USED_SWAP -eq 0 ]]
	then
		echo "No swap memory to free"
	elif [[ $USED_SWAP -lt $FREE_RAM ]]
	then
		echo "Freeing swap memory..."
		swapoff -a
		swapon -a
		echo "Done"
	else
		echo "Unable to free swap memory" && exit 1
	fi
else
	echo "Requires sudo privileges to run" && exit 1
fi
