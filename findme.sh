#!/bin/bash

#### SCRIPT TO FIND PUBLIC IP INFORMATION ####
# Created: May, 2022
# Creator: Leandro Schabarum
# Contact: leandroschabarum.98@gmail.com
##############################################
# Exit codes:
# 0 - Successfully executed script
# 1 - Execution failed (Generic)
# 2 - Missing required dependencies
##############################################

Help() {
	cat <<- EOF >&1
	$(basename "$0") [OPTIONS]
	Display information about your geographic IP location.

	-a | --all       (optional)  Fully formatted (Long).
	-s | --simple    (optional)  Simplified format (Short).
	-r | --raw       (optional)  Complete JSON formatted output.
	-h | --help      (optional)  Displays help information.
	EOF
}

Dependencies() {
	local DEPENDENCY

	for DEPENDENCY in "$@"
	do
		if ! command -v "$DEPENDENCY" > /dev/null 2>&1
		then
			echo "CRITICAL: Missing '$DEPENDENCY' - Install it first!" >&2
			exit 2
		fi
	done
}

Info() {
	PUBLIC_IP=$(curl -sG 'https://ipinfo.io/ip')
	RESPONSE=$(curl -sG "http://ipwhois.app/json/${PUBLIC_IP:?'PUBLIC_IP is not set'}")

	echo "${RESPONSE:?'RESPONSE is not set'}";
}

# Ensure the required dependencies are installed
Dependencies "curl" "jq"

case "${1:--h}" in
	-a | --all )
		Info | jq '"[" + .ip + " - " + .isp + " " + .asn + "] " + .city + ", " + .region + " - " + .country + ", " + .country_code + " (" + (.latitude|tostring) + "," + (.longitude|tostring) + ")"'
		;;

	-s | --simple )
		Info | jq '.city + " - " + .country + ", " + .country_code'
		;;

	-r | --raw )
		Info | jq .
		;;

	-h | --help ) # Displays help information
		Help
		exit 0
		;;

	* ) # DEFAULT
		echo "ERROR: Invalid script option" >&2
		Help
		exit 1
		;;
esac

exit 0
