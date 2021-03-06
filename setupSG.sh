#!/bin/bash

############# SCRIPT FOR sentinelGoblin SETUP ##############
############################################################
# Created: Jan, 2021                                       #
# Creator: Leandro Schabarum                               #
# Contact: leandroschabarum.98@gmail.com                   #
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

	# --- creation of symlinks to sentinelGoblin files from informed source directory --- #
	read -p "............source directory />_ " sourcedir

	if [[ "$sourcedir" != "" && "$sourcedir" != "$BASE_DIR" ]]
	then
		ln -s "$sourcedir/.logoSG" "$BASE_DIR"
		if [[ $? != 0 ]]
		then
			echo "< no file $sourcedir/.logoSG found >" >> "$LOG_FILE"
		else
			# --- Clears the screen to show ascii logo art --- #
			clear
			cat "$BASE_DIR/.logoSG"
			# ------------------------------------------------ #
		fi

		ln -s "$sourcedir/setupSG.sh" "$BASE_DIR"
		if [[ $? != 0 ]]
		then
			echo "< no file $sourcedir/setupSG.sh found >" >> "$LOG_FILE"
		fi

		ln -s "$sourcedir/runSG.sh" "$BASE_DIR"
		if [[ $? != 0 ]]
		then
			echo "< no file $sourcedir/runSG.sh found >" >> "$LOG_FILE"
		fi

		ln -s "$sourcedir/sentinelGoblin.sh" "$BASE_DIR"
		if [[ $? != 0 ]]
		then
			echo "< no file $sourcedir/sentinelGoblin.sh found >" >> "$LOG_FILE"
		fi
	fi
	# ----------------------------------------------------------------------------------- #

	# --- creation of symlinks to teleAlerts files from informed source directory --- #
	read -p "........teleAlerts directory />_ " alertsdir

	if [[ "$alertsdir" != "" && "$alertsdir" != "$BASE_DIR" ]]
	then
		ln -s "$alertsdir/teleAlerts.py" "$BASE_DIR"
		if [[ $? != 0 ]]
		then
			echo "< no file $alertsdir/teleAlerts.py found >" >> "$LOG_FILE"
		fi

		ln -s "$alertsdir/requirements.txt" "$BASE_DIR"
		if [[ $? != 0 ]]
		then
			echo "< no file $alertsdir/requirements.txt found >" >> "$LOG_FILE"
		fi
	fi
	# ------------------------------------------------------------------------------- #

	`$BASE_DIR/$VENV_DIRNAME/bin/pip install -r "$BASE_DIR/requirements.txt" > /dev/null 2>&1`
	`$BASE_DIR/$VENV_DIRNAME/bin/pip freeze > "$BASE_DIR/.installed"`
	hash=$(sha256sum "$BASE_DIR/.installed" | cut -d ' ' -f 1)
	rm -f "$BASE_DIR/.installed"

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

	read -p "..........telegram bot Token />_ " token
	printf "token = %s\n" "$token" >> "$BASE_DIR/$CONF_FILE"

	read -p "............telegram chat id />_ " chatid
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
			echo "<   confirmation message sent   >"
		fi
	else
		echo "< telegram bot information can be altered later at $BASE_DIR/$CONF_FILE >"
	fi

	if [[ ! -f "$BASE_DIR/sentinelGoblin.sh" ]]
	then
		echo "< sentinelGoblin.sh together with .logoSG, setupSG.sh and runSG.sh, need to be copied over to $BASE_DIR >"
		exit 1
	fi

	CRON_JOB="@reboot bash $BASE_DIR/runSG.sh"  # Default cron job for sentinelGoblin

	if ! `crontab -l | grep -q "$CRON_JOB"`
	then
		read -p "...add a job to crontab in case of reboot? [y/n] />_ " cronAnswer
		if [[ "$cronAnswer" == "y" ]]
		then
			crontab -l > "$BASE_DIR/.cronjobs"
			printf "\n$CRON_JOB\n" >> "$BASE_DIR/.cronjobs"
			crontab "$BASE_DIR/.cronjobs"
			if [[ $? != 0 ]]
			then
				echo "< unable to add job to crontab >"
			fi
		fi
	fi

	read -p "....run SentinelGoblin [y/n] />_ " confirmation
	if [[ "$confirmation" == "y" ]]
	then
		bash "$BASE_DIR/runSG.sh"
	fi

	exit 0
else
	echo ">>>> EXECUTION DENIED - ROOT ACCESS REQUIRED <<<<"
	exit 1
fi
