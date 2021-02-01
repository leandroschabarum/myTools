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

		`$1 > "$BASE_DIR/cave/$2"`
		if [[ $? != 0 ]]
		then
			alert "FAILED: $1 > $2"
			return 1
		else
			return 0
		fi
	}

	function dif() {
		# dif "_new.txt" "_old.txt" #
		echo "$(diff --changed-group-format='%<' --unchanged-group-format='' $1 $2)"
		mv "$BASE_DIR/cave/$1" "$BASE_DIR/cave/$2"
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
		local TEMP_HASH=$($2 | sha256sum | cut -d ' ' -f 1)

		if [[ "$TEMP_HASH" != "$1" ]]
		then
			echo "$TEMP_HASH"
			return 0
		else
			return 1
		fi
	}


	LOGGED=$(who | sha256sum | cut -d ' ' -f 1)

	FIREWALL=$(iptables -L | sha256sum | cut -d ' ' -f 1)
	genFILE "iptables -L" "firewall.txt"

	OPENPORTS=$(netstat -tulpn | grep LISTEN | sha256sum | cut -d ' ' -f 1)
	genFILE "netstat -tulpn | grep LISTEN" "openports.txt"

	while true
	do
		logRITUAL

		# check routines #
		HASH=$(checkSUMcommand "$LOGGED" "who")
		if [ $? == 0 ]
		then
			alert "$(tail -1 /var/log/auth.log)"
			LOGGED=$HASH
		fi

		HASH=$(checkSUMcommand "$FIREWALL" "iptables -L")
		if [ $? == 0 ]
		then
			genFILE "iptables -L" "firewall_new.txt"
			CHANGES=$(dif "firewall_new.txt" "firewall.txt")
			alert "Firewall rules were changed: $CHANGES"
			FIREWALL=$HASH
		fi
		
		HASH=$(checkSUMcommand "$OPENPORTS" "netstat -tulpn | grep LISTEN")
		if [ $? == 0 ]
		then
			genFILE "netstat -tulpn | grep LISTEN" "openports_new.txt"
			CHANGES=$(dif "openports_new.txt" "openports.txt")
			alert "Listening Ports changed: $CHANGES"
			OPENPORTS=$HASH
		fi

		sleep 1
	done
fi
