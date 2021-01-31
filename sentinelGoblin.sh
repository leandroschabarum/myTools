#!/bin/bash

################ SCRIPT FOR sentinelGoblin #################
################     RENOVARE  TELECOM     #################
# Created: Jan, 2021                                       #
# Creator: Leandro Schabarum                               #
# Contact: leandro.schabarum@renovaretelecom.com.br        #
############################################################

# BASE_DIR="/opt/sentinelGoblin"
# `nohup bash "$BASE_DIR/sentinelGoblin.sh" > /dev/null 2>$1 &`

if [[ "$(id -u)" == "0" ]]
then
	# ------------ default install paths and folders ------------ #
	BASE_DIR="/opt/sentinelGoblin"
	LOG_FILE="/var/log/sentinelGoblin.log"
	VENV_DIRNAME="venv"  # python virtual enviroment folder name
	CONF_FILE="gold.conf"  # configuration file name
	# ----------------------------------------------------------- #

	filename_HASH=$(sha256sum "filename" | cut -d ' ' -f 1)

	function checkSUM () {
		# checkSUM filename_HASH "/path/filename" #
		# True : changed | False : no changes #
		local TEMP_HASH=$(sha256sum "$2" | cut -d ' ' -f 1)

		if [[ "$TEMP_HASH" != "$1" ]]
		then
			$1=$(sha256sum "$2" | cut -d ' ' -f 1)
			return 0
		else
			return 1
		fi
	}

	while true; do
		# check routine #
	done
fi
