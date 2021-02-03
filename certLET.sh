#!/bin/bash

################ SCRIPT FOR LETSENCRYPT CERTIFICATE ############
################     GENERATION AND RENEWAL JOB	    ############
################          RENOVARE TELECOM          ############
# Created: Feb, 2021                                           #
# Creator: Leandro Schabarum                                   #
# Contact: leandro.schabarum@renovaretelecom.com.br            #
################################################################

DOMAIN_NAME="test.com"

BASE_DIR="/tmp/letsencrypt"
CERT_DIR="/tmp/letsencrypt-gencerts"
GIT_REPO="https://github.com/letsencrypt/letsencrypt"

CRON_TAG="# >>> DO NOT REMOVE THIS COMENT <<< Certificate renewal routine for $DOMAIN_NAME >>> DO NOT REMOVE THIS COMENT <<< #"
CRON_JOB=$([ "$(id -u)" == "0" ] && echo "0 1 1 */2 * sudo bash $CERT_DIR/certLET.sh" || echo "0 1 1 */2 * bash $CERT_DIR/certLET.sh")


if [[ ! -d "$BASE_DIR" && ! -d "$BASE_DIR/.git" ]]
then
	git clone "$GIT_REPO" > /dev/null 2>&1
	if [ $? != 0 ]
	then
		echo "< CRITICAL - unable to clone git repository >"
		exit 1
	fi
fi

NODIR_FLAG=1

if [[ ! -d "$CERT_DIR" ]]
then
	if ! `mkdir -p "$CERT_DIR"`
	then
		echo "< WARNING - unable to make $CERT_DIR >"
		NODIR_FLAG=0
	else
		ln -s "$(pwd)/certLET.sh" "$CERT_DIR"
		ln -s "$(pwd)/logoLET.txt" "$CERT_DIR"
	fi

	# --- Clears the screen to show ascii logo art --- #
	clear
	cat "$CERT_DIR/logoLET.txt"
	# ------------------------------------------------ #

	if ! `crontab -l | grep -q "$CRON_JOB_TAG"`
	then
		read -p "/>_ would you like to add this job to crontab? [y/n]" cronAnswer
		if [[ "$cronAnswer" == "y" ]]
		then
			crontab -l > "$CERT_DIR/.cronjobs"
			printf "\n$CRON_TAG\n$CRON_JOB\n" >> "$CERT_DIR/.cronjobs"
			crontab "$CERT_DIR/.cronjobs"
			if [ $? != 0 ]
			then
				echo "< WARNING - unable to add job >"
			fi
		fi
	fi
fi
