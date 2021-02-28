#!/bin/bash

################ SCRIPT FOR LETSENCRYPT CERTIFICATE ############
################     GENERATION AND RENEWAL JOB	    ############
# Created: Feb, 2021                                           #
# Creator: Leandro Schabarum                                   #
# Contact: leandroschabarum.98@gmail.com                       #
################################################################

MAIN_DOMAIN="-d <domain_name>"
# MAIN_DOMAIN has to be the domain name that LetsEncrypt uses to
# create the certificates folder inside its /live directory
OTHER_DOMAINS="-d <domain_name1> -d <domain_name2>"
USER="<user>"
GROUP="<group>"
APPLICATION="<app>"

# ------------ default install paths and folders ------------ #
CERT_DIR="/opt/letsencrypt-gencerts"
BASE_DIR="/opt/letsencrypt"
LETSENCRYPT_CERTDIR="/etc/letsencrypt/live"
GIT_REPO="https://github.com/letsencrypt/letsencrypt"
# ----------------------------------------------------------- #
LIVE_FOLDER=$(echo $MAIN_DOMAIN | cut -d ' ' -f 2)
CRON_TAG="# DO NOT REMOVE THIS COMMENT - Certificate renewal routine for $LIVE_FOLDER - DO NOT REMOVE THIS COMMENT #"
CRON_JOB=$([ "$(id -u)" == "0" ] && echo "0 1 15 */2 * sudo bash $CERT_DIR/certLET.sh" || echo "0 1 15 */2 * bash $CERT_DIR/certLET.sh")


function createLOG() {
	if [[ ! -f "$CERT_DIR/certLET.log" ]]
	then
		touch "$CERT_DIR/certLET.log"
		if [[ $? != 0 ]]
		then
			echo "< CRITICAL - unable to create $CERT_DIR/certLET.log >"
			exit 1
		else
			chmod 640 "$CERT_DIR/certLET.log"
		fi
	fi
}

function logARCHIVE() {
	if [[ -f "$CERT_DIR/certLET.log" ]]
	then
		local SIZE=$(du --block=1 "$CERT_DIR/certLET.log" | cut -f 1)

		if (( SIZE > 10000000 ))
		then
			local COUNT=$(ls $CERT_DIR | grep "certLET.log*" | wc -l)
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


if [[ ! -d "$CERT_DIR" ]]
then
	if ! `mkdir -p "$CERT_DIR"`
	then
		echo "< WARNING - unable to make $CERT_DIR >"
	else
		if [[ "$(pwd)" != "$CERT_DIR" ]]
		then
			ln -s "$(pwd)/certLET.sh" "$CERT_DIR"
		fi

		createLOG
	fi

	if ! `crontab -l | grep -q "$CRON_TAG"`
	then
		read -p "...would you like to add a renewal job to crontab? [y/n] />_ " cronAnswer
		if [[ "$cronAnswer" == "y" ]]
		then
			crontab -l > "$CERT_DIR/.cronjobs"
			printf "\n$CRON_TAG\n$CRON_JOB\n" >> "$CERT_DIR/.cronjobs"
			crontab "$CERT_DIR/.cronjobs"
			if [[ $? != 0 ]]
			then
				echo "< WARNING - unable to add job to crontab >" >> "$CERT_DIR/certLET.log"
			fi
		fi
	fi
fi

logARCHIVE

if [[ ! -d "$BASE_DIR" && ! -d "$BASE_DIR/.git" ]]
then

	`git clone "$GIT_REPO" "$BASE_DIR" >> "$CERT_DIR/certLET.log" 2>&1`
	if [[ $? != 0 ]]
	then
		echo "< CRITICAL - unable to clone git repository >" >> "$CERT_DIR/certLET.log" 2>&1`
		exit 1
	fi
fi

if [[ "$MAIN_DOMAIN" == "" ]]
then
	echo "< CRITICAL - no domain name informed >" >> "$CERT_DIR/certLET.log"
	exit 1
elif [[ "$OTHER_DOMAINS" != "" ]]
then
	`systemctl stop "$APPLICATION" > /dev/null 2>&1`
	sleep 1
	"$BASE_DIR/letsencrypt-auto" certonly --standalone $MAIN_DOMAIN $OTHER_DOMAINS >> "$CERT_DIR/certLET.log"
else
	`systemctl stop "$APPLICATION" > /dev/null 2>&1`
	sleep 1
	"$BASE_DIR/letsencrypt-auto" certonly --standalone $MAIN_DOMAIN >> "$CERT_DIR/certLET.log"
fi


if [[ -d "$LETSENCRYPT_CERTDIR/$LIVE_FOLDER" && -d "$CERT_DIR" ]]
then
	cp "$LETSENCRYPT_CERTDIR/$LIVE_FOLDER/cert.pem" "$LETSENCRYPT_CERTDIR/$LIVE_FOLDER/privkey.pem" "$LETSENCRYPT_CERTDIR/$LIVE_FOLDER/fullchain.pem" "$CERT_DIR/."
	if [[ $? == 0 ]]
	then
		if [[ "$USER" != "" && "$GROUP" != "" ]]
		then
			if ! `chown -R "$USER:$GROUP" "$CERT_DIR"`
			then
				echo "< WARNING - unable to set ownership of $LETSENCRYPT_CERTDIR to $USER:$GROUP >" >> "$CERT_DIR/certLET.log"
			fi
		fi
	else
		echo "< WARNING - failed to copy certificate and private key from $LETSENCRYPT_CERTDIR/$LIVE_FOLDER >" >> "$CERT_DIR/certLET.log"
		exit 1
	fi
else
	echo "< CRITICAL - unable to find $LETSENCRYPT_CERTDIR/$LIVE_FOLDER >" >> "$CERT_DIR/certLET.log"
	exit 1
fi


`systemctl start "$APPLICATION"`
sleep 1
`systemctl is-active --quiet "$APPLICATION"`
if [[ $? != 0 ]]
then
	echo "< CRITICAL - service $APPLICATION is not active >"
	exit 1
else
	exit 0
fi
