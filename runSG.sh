#!/bin/bash

################ SCRIPT FOR sentinelGoblin RUN #################
################       RENOVARE  TELECOM       #################
# Created: Jan, 2021                                           #
# Creator: Leandro Schabarum                                   #
# Contact: leandro.schabarum@renovaretelecom.com.br            #
################################################################

# ps -ef | grep -w 'sudo' | cut -d ' ' -f 7

if [[ "$(id -u)" == "0" ]]
then
	BASE_DIR="/opt/sentinelGoblin"

	nohup bash "$BASE_DIR/sentinelGoblin.sh" > "$BASE_DIR/.sgpid" 2>&1 &
	PID="$!"
	if [[ $? == 0 ]]
	then
		echo "$PID - runSG.sh" > "$BASE_DIR/.sgpid"
		exit 0
	else
		echo ">>>> UNABLE TO RUN <<<<"
		exit 1
	fi
else
	echo ">>>> EXECUTION DENIED - ROOT ACCESS REQUIRED <<<<"
	exit 1
fi
