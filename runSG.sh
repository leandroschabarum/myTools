#!/bin/bash

################ SCRIPT FOR sentinelGoblin RUN #################
################       RENOVARE  TELECOM       #################
# Created: Jan, 2021                                           #
# Creator: Leandro Schabarum                                   #
# Contact: leandro.schabarum@renovaretelecom.com.br            #
################################################################


if [[ "$(id -u)" == "0" ]]
then
	BASE_DIR="/opt/sentinelGoblin"
	PID_FLAG=$(pgrep -lf ".[ /]sentinelGoblin.sh( |\$)")

	if [[ "$PID_FLAG" == "" ]]
	then
		nohup bash "$BASE_DIR/sentinelGoblin.sh" >> "$BASE_DIR/.sgpid" 2>&1 &
		echo "/>_ nohup exit: $?" # DEBUG LINE
		if [[ $? == 0 ]]
		then
			PID=$(pgrep -lf ".[ /]sentinelGoblin.sh( |\$)" | cut -d ' ' -f 1)
			echo "$PID - runSG.sh >>> sentinelGoblin.sh" > "$BASE_DIR/.sgpid"
			exit 0
		else
			echo ">>>> UNABLE TO RUN <<<<"
			exit 1
		fi
	else
		echo ">>>> ALREADY RUNNING - $PID_FLAG <<<<" >> "$BASE_DIR/.sgpid"
	fi
else
	echo ">>>> EXECUTION DENIED - ROOT ACCESS REQUIRED <<<<"
	exit 1
fi
