#!/bin/bash

############ SCRIPT TO CHECK AND CLEAR ############
############     LINUX SWAP MEMORY     ############
# Created: Mar, 2020
# Creator: Leandro Schabarum
# Contact: leandroschabarum.98@gmail.com
###################################################
# Exit codes:
# 0 - Successfully executed script
# 1 - Execution failed (Generic)
###################################################

# Ensure script is executed with root privileges
if [[ $(id -u) -ne 0 ]]
then
	echo "ERROR: Requires sudo privileges to run" >&2
	exit 1
fi

# Ensure required information is processed
MEMORY="$(free -b)"
FREE_RAM="$(echo "$MEMORY" | grep 'Mem:' | awk '{print $7}')"
USED_SWAP="$(echo "$MEMORY" | grep 'Swap:' | awk '{print $3}')"

if [[ $USED_SWAP -eq 0 ]]
then
	echo "SUCCESS: No swap memory to free" >&1
elif [[ $USED_SWAP -lt $FREE_RAM ]]
then
	echo "INFO: Freeing swap memory..."
	swapoff -a
	swapon -a
	echo "SUCCESS: Swap freed" >&1
else
	echo "ERROR: Unable to free swap memory" >&2
	exit 1
fi

exit 0
