#!/bin/bash

############# SCRIPT FOR sentinelGoblin SETUP ##############
#############        RENOVARE  TELECOM        ##############
# Created: Jan, 2021                                       #
# Creator: Leandro Schabarum                               #
# Contact: leandro.schabarum@renovaretelecom.com.br        #
############################################################

PYTHON="python3.8"  # check python executable to match required version
VENV_DIRNAME="venv"  # default virtual enviroment name
CONF_FILE="alerts.conf"  # default .conf file name
BASE_DIR="/dev/sentinelGoblin"  # default base directory path
LOG_FILE="/var/log/sentinelGoblin.log"  # default log file path


if [[ ! -f "$LOG_FILE" ]]; then
	touch "$LOG_FILE"
	if [[ $? != 0 ]]; then
		echo "< unable to create $LOG_FILE >"
		exit 1
	else
		chmod 640 "$LOG_FILE"
		chown root:root "$LOG_FILE"
	fi
fi

if [[ ! -d "$BASE_DIR" ]]; then
	mkdir "$BASE_DIR"
	if [[ $? != 0 ]]; then
		echo "< unable to create $BASE_DIR >" >> "$LOG_FILE"
	fi
fi

if [[ ! -d "$BASE_DIR/$VENV_DIRNAME" ]]; then
	`$PYTHON -m venv $VENV_DIRNAME`
	echo "$PYTHON -m venv $VENV_DIRNAME"
	if[[ $? != 0 ]]; then
		echo "< unable to create $BASE_DIR/$VENV_DIRNAME >" >> "$LOG_FILE"
		exit 1
	fi
fi

read -p ".....source directory />_ " sourcedir

if [[ "$sourcedir" != "" && "$sourcedir" != "$(pwd)" ]]; then
	ln -s "$sourcedir/teleAlerts.py" "$BASE_DIR"
	if [[ $? != 0 ]]; then
		echo "< no file $sourcedir/teleAlerts.py found >" >> "$LOG_FILE"
	fi

	ln -s "$sourcedir/requirements.txt" "$BASE_DIR"
	if [[ $? != 0 ]]; then
		echo "< no file $sourcedir/requirements.txt found >" >> "$LOG_FILE"
	fi
fi

`$BASE_DIR/$VENV_DIRNAME/bin/pip install -r requirements.txt`

if[[ $? != 0 ]]; then
	echo "< unable to set up python dependencies >" >> "$LOG_FILE"
fi


if [[ ! -f "$BASE_DIR/$CONF_FILE" ]]; then
	touch "$BASE_DIR/$CONF_FILE" && printf "[TELEGRAM_chat_info]" > "$BASE_DIR/$CONF_FILE"
	if [[ $? != 0 ]]; then
		echo "< unable to create $BASE_DIR/$CONF_FILE >"
		exit 1
	else
		printf "token = " >> "$BASE_DIR/$CONF_FILE"
		printf "chatid = " >> "$BASE_DIR/$CONF_FILE"
		chmod 600 "$BASE_DIR/$CONF_FILE"
		chown root:root "$BASE_DIR/$CONF_FILE"
	fi
fi

echo "< information is being written to $BASE_DIR/$CONF_FILE >"
printf "[TELEGRAM_chat_info]" > "$BASE_DIR/$CONF_FILE"

read -p "...telegram bot Token />_ " token
printf "token = %s" "$token" >> "$BASE_DIR/$CONF_FILE"

read -p ".....telegram chat id />_ " chatid
printf "chatid = %s" "$chatid" >> "$BASE_DIR/$CONF_FILE"

if [[ "$token" != "" && "$chatid" != "" ]]; then
	echo "< setup finished succesfully >" | "$BASE_DIR/$VENV_DIRNAME/bin/python" "$BASE_DIR/teleAlerts.py"
	if [[ $? != 0 ]]; then
		NOW=$(date +"%d%m%Y - %H%M%S")
		echo "$NOW />_ UNABLE TO SEND TEST MESSAGE - setup failed" >> "$LOG_FILE"
		exit 1
	else
		echo "< confirmation message sent >"
	fi
fi

exit 0
