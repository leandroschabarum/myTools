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
BASE_DIR="/opt/letsencrypt"
CERT_DIR="/opt/letsencrypt-gencerts"
GIT_REPO="https://github.com/letsencrypt/letsencrypt"
# ----------------------------------------------------------- #
CRON_TAG="# DO NOT REMOVE THIS COMMENT - Certificate renewal routine for $MAIN_DOMAIN - DO NOT REMOVE THIS COMMENT #"
CRON_JOB=$([ "$(id -u)" == "0" ] && echo "0 1 15 */2 * sudo bash $CERT_DIR/certLET.sh" || echo "0 1 15 */2 * bash $CERT_DIR/certLET.sh")


if [[ ! -d "$BASE_DIR" && ! -d "$BASE_DIR/.git" ]]
then

	`git clone "$GIT_REPO" "$BASE_DIR" > /dev/null 2>&1`
	if [[ $? != 0 ]]
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
		if [[ "$(pwd)" != "$CERT_DIR" ]]
		then
			ln -s "$(pwd)/certLET.sh" "$CERT_DIR"
		fi
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
				echo "< WARNING - unable to add job to crontab >"
			fi
		fi
	fi
fi

BREAK_FLAG=0

if [[ "$MAIN_DOMAIN" == "" ]]
then
	echo "< CRITICAL - no domain name informed >"
	exit 1
elif [[ "$OTHER_DOMAINS" != "" ]]
then
	`systemctl stop "$APPLICATION"`
	`"$BASE_DIR/letsencrypt-auto" certonly --standalone "$MAIN_DOMAIN" "$OTHER_DOMAINS" > /dev/null 2>&1`
	if [[ $? != 0 ]]
	then
		BREAK_FLAG=1
	fi
else
	`systemctl stop "$APPLICATION"`
	`"$BASE_DIR/letsencrypt-auto" certonly --standalone "$MAIN_DOMAIN" > /dev/null 2>&1`
	if [[ $? != 0 ]]
	then
		BREAK_FLAG=1
	fi
fi

if [[ "$BREAK_FLAG" != "0" ]]
then
	echo "< CRITICAL - unable to generate certificate and private key >"
	`systemctl start "$APPLICATION"`
	sleep 1
	`systemctl is-active --quiet "$APPLICATION"`
	if [[ $? != 0 ]]
	then
		echo "< CRITICAL - service $APPLICATION is not active >"
	fi
	exit 1
fi

LETSENCRYPT_CERTDIR="/etc/letsencrypt/live"  # Default directory for LetsEncrypt certificates and private keys

if [[ -d "$LETSENCRYPT_CERTDIR/$MAIN_DOMAIN" && "$CERT_DIR" ]]
then
	if [[ -f "$LETSENCRYPT_CERTDIR/$MAIN_DOMAIN/privkey.pem" && -f "$LETSENCRYPT_CERTDIR/$MAIN_DOMAIN/fullchain.pem" ]]
	then
		cp "$LETSENCRYPT_CERTDIR/$MAIN_DOMAIN/fullchain.pem" "$LETSENCRYPT_CERTDIR/$MAIN_DOMAIN/privkey.pem" "$CERT_DIR/"
		if [[ $? == 0 ]]
		then
			if [[ "$USER" != "" && "$GROUP" != "" ]]
			then
				if ! `chown -R "$USER:$GROUP" "$CERT_DIR"`
				then
					echo "< WARNING - unable to set ownership of $LETSENCRYPT_CERTDIR to $USER:$GROUP >"
				fi
			fi
		else
			echo "< WARNING - failed to copy certificate and private key from $LETSENCRYPT_CERTDIR/$MAIN_DOMAIN >"
			exit 1
		fi
	fi
else
	echo "< CRITICAL - unable to create copy of certificate and private key >"
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
