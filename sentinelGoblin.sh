#!/bin/bash

################ SCRIPT FOR sentinelGoblin #################
################     RENOVARE  TELECOM     #################
# Created: Jan, 2021                                       #
# Creator: Leandro Schabarum                               #
# Contact: leandro.schabarum@renovaretelecom.com.br        #
############################################################


if [[ "$(id -u)" == "0" ]]
then
	# ------------ default install paths and folders ------------ #
	BASE_DIR="/opt/sentinelGoblin"
	LOG_FILE="/var/log/sentinelGoblin.log"
	VENV_DIRNAME="venv"  # python virtual enviroment folder name
	CONF_FILE="gold.conf"  # configuration file name
	# ----------------------------------------------------------- #

	function alert() {
		echo "$1" | "$BASE_DIR/$VENV_DIRNAME/bin/python" "$BASE_DIR/teleAlerts.py"
		if [[ $? != 0 ]]
		then
			local NOW=$(date +"%d%m%Y - %H%M%S")
			echo "$NOW />_ UNABLE TO SEND ALERT MESSAGE: $1" >> "$LOG_FILE"
			return 1
		else
			return 0
		fi
	}

	function createLOG() {
		if [[ ! -f "$LOG_FILE" ]]
		then
			touch "$LOG_FILE"
			if [[ $? != 0 ]]
			then
				echo "< unable to create $LOG_FILE >"
				return 1
			else
				chmod 640 "$LOG_FILE"
				chown root:root "$LOG_FILE"
				return 0
			fi
		fi
	}

	function logRITUAL() {
		if [[ -f "$LOG_FILE" ]]
		then
			local SIZE=$(du --block=1 "$LOG_FILE" | cut -f 1)

			if (( SIZE > 100000000 ))
			then
				local COUNT=$(ls /var/log | grep "sentinelGoblin.log*" | wc -l)
				mv "$LOG_FILE" "$LOG_FILE.$COUNT"
				if [[ $? == 0 ]]
				then
					createLOG
					return 0
				else
					return 1
				fi
			fi
		else
			createLOG
			return 1
		fi
	}

	function genFILE () {
		# genFILE "command" "output.txt" #
		# True : ok | False : failed     #
		if [[ ! -d "$BASE_DIR/cave" ]]
		then
			mkdir "$BASE_DIR/cave" > /dev/null 2>&1
			if [[ $? == 0 ]]
			then
				chmod 700 "$BASE_DIR"
				chown root:root "$BASE_DIR"
			fi
		fi

		`"$1" > "$BASE_DIR/cave/$2"`
		if [[ $? != 0 ]]
		then
			alert "FAILED: $1 > $2"
			return 1
		else
			return 0
		fi
	}

	function checkSUMfile () {
		# checkSUM "$HASH" "/path/filename" #
		# True : changed | False : no changes     #
		local TEMP_HASH=$(sha256sum "$2" | cut -d ' ' -f 1)

		if [[ "$TEMP_HASH" != "$1" ]]
		then
			echo "$TEMP_HASH"
			return 0
		else
			return 1
		fi
	}

	function checkSUMcommand () {
		# checkSUM "$HASH" "command" #
		# True : changed | False : no changes     #
		local TEMP_HASH=$("$2" | sha256sum | cut -d ' ' -f 1)

		if [[ "$TEMP_HASH" != "$1" ]]
		then
			echo "$TEMP_HASH"
			return 0
		else
			return 1
		fi
	}


	LOGGED_IN=$(who | sha256sum | cut -d ' ' -f 1)

	while true
	do
		logRITUAL
		# check routine #
		# iptables -L > firewallRules.txt #
		
		OUTPUT=$(checkSUMcommand "$LOGGED_IN" "who")
		if [ $? == 0 ]
		then
			alert "test - access changes"
			LOGGED_IN=$OUTPUT
		fi

		sleep 1
	done
fi
