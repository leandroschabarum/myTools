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
                echo "no swap memory to free"
        elif [[ $USED_SWAP -lt $FREE_RAM ]]
        then
                echo "freeing swap memory..."
                swapoff -a
                swapon -a
                echo "done"
        else
                echo "unable to free swap memory"
                exit 1
        fi
else
        echo "requires sudo privileges to run"
        exit 1
fi
