#!/bin/bash

############# SCRIPT FOR sentinelGoblin SETUP ##############
#############        RENOVARE  TELECOM        ##############
# Created: Jan, 2021                                       #
# Creator: Leandro Schabarum                               #
# Contact: leandro.schabarum@renovaretelecom.com.br        #
############################################################

if [[ "$(id -u)" == "0" ]]
then
	PYTHON="python3.8"  # check python executable to match required version

	# ------------ default install paths and folders ------------ #
	BASE_DIR="/opt/sentinelGoblin"
	LOG_FILE="/var/log/sentinelGoblin.log"
	VENV_DIRNAME="venv"  # python virtual enviroment folder name
	CONF_FILE="gold.conf"  # configuration file name
	# ----------------------------------------------------------- #

	if [[ ! -f "$LOG_FILE" ]]
	then
		touch "$LOG_FILE"
		if [[ $? != 0 ]]
		then
			echo "< unable to create $LOG_FILE >"
			exit 1
		else
			chmod 640 "$LOG_FILE"
			chown root:root "$LOG_FILE"
		fi
	fi

	if [[ ! -d "$BASE_DIR" ]]
	then
		mkdir "$BASE_DIR"
		if [[ $? != 0 ]]
		then
			echo "< unable to create $BASE_DIR >" >> "$LOG_FILE"
		else
			chmod 700 "$BASE_DIR"
			chown root:root "$BASE_DIR"
		fi
	fi

	if [[ ! -d "$BASE_DIR/$VENV_DIRNAME" ]]
	then
		`$PYTHON -m venv "$BASE_DIR/$VENV_DIRNAME" > /dev/null 2>&1`
		if [[ $? != 0 ]]
		then
			echo "< unable to create $BASE_DIR/$VENV_DIRNAME >" >> "$LOG_FILE"
			exit 1
		fi
	fi

	read -p ".....source directory />_ " sourcedir

	if [[ "$sourcedir" != "" && "$sourcedir" != "$(pwd)" ]]
	then
		ln -s "$sourcedir/teleAlerts.py" "$BASE_DIR"
		if [[ $? != 0 ]]
		then
			echo "< no file $sourcedir/teleAlerts.py found >" >> "$LOG_FILE"
		fi

		ln -s "$sourcedir/requirements.txt" "$BASE_DIR"
		if [[ $? != 0 ]]
		then
			echo "< no file $sourcedir/requirements.txt found >" >> "$LOG_FILE"
		fi
	fi

	`$BASE_DIR/$VENV_DIRNAME/bin/pip install -r "$BASE_DIR/requirements.txt" > /dev/null 2>&1`
	`$BASE_DIR/$VENV_DIRNAME/bin/pip freeze > "$BASE_DIR/installed.txt"`
	hash=$(sha256sum "$BASE_DIR/installed.txt" | cut -d ' ' -f 1)
	rm -f "$BASE_DIR/installed.txt"

	if [[ "$hash" !=  "$(sha256sum "$BASE_DIR/requirements.txt"  | cut -d ' ' -f 1)" ]]
	then
		echo "< python dependencies differ from source >" >> "$LOG_FILE"
	fi

	if [[ ! -f "$BASE_DIR/$CONF_FILE" ]]
	then
		touch "$BASE_DIR/$CONF_FILE" && printf "[TELEGRAM_chat_info]\n" > "$BASE_DIR/$CONF_FILE"
		if [[ $? != 0 ]]
		then
			echo "< unable to create $BASE_DIR/$CONF_FILE >"
			exit 1
		else
			printf "token = \n" >> "$BASE_DIR/$CONF_FILE"
			printf "chatid = \n" >> "$BASE_DIR/$CONF_FILE"
			chmod 600 "$BASE_DIR/$CONF_FILE"
			chown root:root "$BASE_DIR/$CONF_FILE"
		fi
	fi

	echo "< information is being written to $BASE_DIR/$CONF_FILE >"
	printf "[TELEGRAM_chat_info]\n" > "$BASE_DIR/$CONF_FILE"

	read -p "...telegram bot Token />_ " token
	printf "token = %s\n" "$token" >> "$BASE_DIR/$CONF_FILE"

	read -p ".....telegram chat id />_ " chatid
	printf "chatid = %s\n" "$chatid" >> "$BASE_DIR/$CONF_FILE"

	if [[ "$token" != "" && "$chatid" != "" ]]
	then
		echo "< setup finished succesfully >" | "$BASE_DIR/$VENV_DIRNAME/bin/python" "$BASE_DIR/teleAlerts.py"
		if [[ $? != 0 ]]
		then
			NOW=$(date +"%d%m%Y - %H%M%S")
			echo "$NOW />_ UNABLE TO SEND TEST MESSAGE - setup failed" >> "$LOG_FILE"
			exit 1
		else
			echo "< confirmation message sent >"
		fi
	fi

	exit 0
else
	echo ">>>> EXECUTION DENIED - ROOT ACCESS REQUIRED <<<<"
fi

exit 1
