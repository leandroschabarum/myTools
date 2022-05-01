#!/bin/bash

reset="\\033[0m"
yellow="\\033[1;33m"
red="\\033[1;31m"

Help() {
	cat <<- EOF >&1
	Display information about your geographic IP location.
	$(basename "$0") [OPTIONS]
	-a|--all	(optional)	Fully formatted (Long)
	-s|--simple	(optional)	Simplified format (Short)
	-r|--raw	(optional)	JSON formatted
	-h|--help	(optional)	Displays help information
	EOF
}

Required() {
	if ! command -v "${1:?'Dependency not set'}" > /dev/null 2>&1
	then
		echo -e "${red}Missing $1, please install it first!${reset}" >&2
		exit 1
	fi
}

Info() {
	PUBLIC_IP=$(curl -sG 'https://ipinfo.io/ip')
	RESPONSE=$(curl -sG "http://ipwhois.app/json/${PUBLIC_IP:?'PUBLIC_IP is not set'}")

	echo "${RESPONSE:?'RESPONSE is not set'}";
}

Required curl
Required jq

case "${1:--h}" in
	-a | --all )
	Info | jq '"[" + .ip + " - " + .isp + " " + .asn + "] " + .city + ", " + .region + " - " + .country + ", " + .country_code + " (" + (.latitude|tostring) + "," + (.longitude|tostring) + ")"'
	exit 0
	;;

	-s | --simple )
	Info | jq '.city + " - " + .country + ", " + .country_code'
	exit 0
	;;

	-r | --raw )
	Info | jq .
	exit 0
	;;

	-h | --help ) # Displays help information
	Help
	exit 0
	;;

	* ) # Displays help information and return error
	echo -e "${yellow}ERROR: Invalid option${reset}" >&2
	Help
	exit 1
	;;
esac
