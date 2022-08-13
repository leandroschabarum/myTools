#!/bin/bash

Help() {
	cat <<- EOF >&1
	Display information about the server's power supply.
	$(basename "$0") [OPTIONS]
	-b|--bat	(required)	Battery device identifier
	-c|--cfg	(required)	Configuration file
	-h|--help	(optional)	Display help information
	EOF
}

# Parse command line options
while [[ "$1" =~ ^(-|--) ]]
do
	case "$1" in
		-b | --bat )
			shift # Shift when option has an argument
			BATTERY="${1:?'WARN: Missing battery device'}"
			;;

		-c | --cfg )
			shift # Shift when option has an argument
			CFG_FILE="${1:?'WARN: Missing configuration file'}"
			;;

		-h | --help ) # Display the help information
			Help
			exit 0
			;;

		* ) # DEFAULT
			echo "ERROR: Invalid option" >&2
			Help
			exit 1
			;;
	esac
	shift # Advance to the next option
done

# Validate configuration file parameters
if [[ -r "{$CFG_FILE:?'ERROR: Configuration file not set'}" ]]
then
	# Configuration file must contain:
	#	token	- Telegram bot token
	#	chatid	- Telegram group chat id
	#	log		- Log file
	#	limit	- Auto shutdown when battery is under this percentage
	source "$CFG_FILE"

	if [[ -z "${token}" || -z "${chatid}" || -z "${log}" || -z "${limit}" ]]
	then
		echo "ERROR: Missing required configuration parameters"
		exit 1
	fi
else
	echo "ERROR: Unable to find/read configuration file"
	exit 1
fi

# Check curl dependency for alerts
if ! command -v curl > /dev/null 2>&1
then
        echo "ERROR: Missing curl dependency" >&2
        exit 1
fi

# Retrieve battery status and charge level from sys filesystem
SYS_FILE="/sys/class/power_supply/${BATTERY:?'ERROR: Battery device not set'}"
STATUS="$(cat "${SYS_FILE:?'ERROR: Filesystem dir not set'}/status")"
CHARGE="$(cat "${SYS_FILE:?'ERROR: Filesystem dir not set'}/capacity")"

# Function for logging messages
logger() {
	local MSG

	MSG="${1:?'WARN: Missing message argument'}"

	echo "$(date +"[%Y-%m-%d %H:%M:%S]") ${MSG}" >> "${log}" && return 0
}

# Function for sending Telegram alerts
sendAlert() {
	local MSG RESPONSE

	# expected positional argument check and message composition
	read -r -d '' MSG <<- EOF
	&#10071; <b>[$(hostname)]</b> <i>$(date +"%Y-%m-%d %H:%M:%S")</i>
	${1:?'WARN: Missing message argument'}
	EOF

	REQUEST_URL="https://api.telegram.org/bot${token}/sendMessage"
	# Telegram API request using curl and grep to retrieve confirmation that message was send successfully
	RESPONSE="$(curl --location --request GET "$REQUEST_URL" \
		--data-urlencode "chat_id=${chatid}" \
		--data-urlencode "parse_mode=HTML" \
		--data-urlencode "text=${MSG:?'ERROR: Empty message'}" \
		2>&1)"

	# if no {"ok":true} response is received, defaults to returning failed notification status
	[[ "$(echo "${RESPONSE:='empty'}" | grep -o -E '"ok":( +)?[[:alnum:]]+[^,]' | cut -d ':' -f 2)" =~ true ]] && return 0
	logger "Failed to send Telegram notification <${RESPONSE:='empty'}>" && return 1
}

# Evaluates control variable if it is unset
if [[ -z "${PWRSPLY+x}" ]]
then
	export PWRSPLY=0
fi

# Evaluates current host power state
case "${STATUS:?'WARN: Status not set'}" in
	Full)
		if (( $PWRSPLY > 0 ))
		then
			logger "[On AC power] Battery is fully charged"
			sendAlert "[On AC power] Battery is fully charged"
		fi

		export PWRSPLY=0 && exit 0
		;;
	Charging)
		logger "[On AC power] Battery is charging ( ${CHARGE:-###}% )"

		if (( $PWRSPLY > 1 ))
		then
			sendAlert "[On AC power] Battery is charging ( ${CHARGE:-###}% )"
		fi

		export PWRSPLY=1 && exit 0
		;;
	Discharging)
		logger "[On battery power] Battery is discharging ( ${CHARGE:-###}% )"

		if (( ${CHARGE:-100} < $limit ))
		then
			logger "[Shutdown] The system will be shutdown to reserve battery for disaster prevention"
			sendAlert "[Shutdown] The system will be shutdown to reserve battery for disaster prevention"

			# Machine will be shutdown after one minute
			#shutdown -P +1
		fi

		if (( $PWRSPLY > 2 ))
		then
			sendAlert "[On Battery power] Battery is discharging ( ${CHARGE:-###}% )"
		fi

		export PWRSPLY=2 && exit 0
		;;
	*) # DEFAULT
		logger "[Action required] Unknown power state"

		if (( $PWRSPLY > 3 ))
		then
			sendAlert "[Action required] Unknown power state"
		fi

		export PWRSPLY=3 && exit 1
		;;
esac
