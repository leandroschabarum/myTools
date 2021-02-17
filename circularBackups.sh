#!/bin/bash

############## SCRIPT TO MANAGE BACKUP FILES ###############
##############       RENOVARE  TELECOM       ###############
# Created: Feb, 2020                                       #
# Creator: Leandro Schabarum                               #
# Contact: leandro.schabarum@renovaretelecom.com.br        #
############################################################


BASE_DIR="/var/log"  # Default base directory for log folder

if [[ ! -d "$BASE_DIR/circular_backups" ]]
then
        mkdir -p "$BASE_DIR/circular_backups"
fi

function logARCHIVE() {
        if [[ -f "$BASE_DIR/circular_backups/journal.log" ]]
        then
                local SIZE=$(du --block=1 "$BASE_DIR/circular_backups/journal.log" | cut -f 1)

                if (( SIZE > 10000000 ))
                then
                        local COUNT=$(ls $BASE_DIR/circular_backups | grep '^journal.log*' | wc -l)
                        `mv "$BASE_DIR/circular_backups/journal.log" "$BASE_DIR/circular_backups/journal.log.$COUNT"`
                fi
        else
                touch "$BASE_DIR/circular_backups/journal.log"
        fi
}

function mostRecentFile() {
        # $1 ---> backup files directory - absolute path #
        # $2 ---> file name pattern                      #
        local lastDate="0"

        for file in `ls "$1" | grep "$2"`
        do
                local mtime=$(stat "$1/$file" | grep '^Modify:' | cut -d ' ' -f 2)

                if [[ `date +'%Y-%m-%d' --date="$mtime"` > "$lastDate" ]]
                then
                        lastDate=$(date +'%Y-%m-%d' --date="$mtime")
                fi
        done

        echo "$lastDate"
}

function removeOlderFiles() {
        # $1 ---> starting date string, ISO FORMAT (YYY-MM-DD)        #
        # $2 ---> keep files up to how many days before starting date #
        # $3 ---> backup files directory - absolute path              #
        # $4 ---> file name pattern                                   #
        local referenceDate=$(date +'%Y-%m-%d' --date="$1 $2")

        for file in `ls "$3" | grep "$4"`
        do
                local mtime=$(stat "$3/$file" | grep '^Modify:' | cut -d ' ' -f 2)

                if [[ "$referenceDate" > `date +'%Y-%m-%d' --date="$mtime"` ]]
                then
                        if ! echo "[ $mtime : $referenceDate ] />_ ( $3/$file )"  # `rm -rf "$3/$file"` #
                        then
                                echo "<$(date)> unable to remove $3/$file" >> "$BASE_DIR/circular_backups/journal.log"
                        fi
                fi
        done

        return 0
}

logARCHIVE
# Calls for management routine #

DATE_REF=$(mostRecentFile "/path/to/dir" "file_pattern")
removeOlderFiles "$DATE_REF" "7 day ago" "/path/to/dir" "file_pattern"  # Backups from <*>
