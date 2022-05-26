#!/bin/bash

################ SCRIPT TO CLEAR CACHE ################
# Created: Mar, 2020                                  #
# Creator: Leandro Schabarum                          #
# Contact: leandroschabarum.98@gmail.com              #
#######################################################

while getopts ":^c$:^i$:^a$" opt
do
        case $opt in
                c)
                        FLAG=1
                        ;;
                i)
                        FLAG=2
                        ;;
                a)
                        FLAG=3
                        ;;
                \?)
                        echo "dcache [ -c : -i : -a]"
                        echo "-c ....... clears only PageCache"
                        echo "-i ....... clears only Dentries and Inodes"
                        echo "-a ....... clears all PageCache, Dentries and Inodes"
                        exit 1
                        ;;
                :)
                        echo "requires flag option"
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
                echo "done"
        fi
else
        echo "requires sudo privileges to run"
        exit 1
fi
