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
	Display information about the server's power supply.

	-b | --bat <dev>     (required)  Battery device identifier.
	-c | --cfg <path>    (required)  Configuration file.
	-h | --help          (optional)  Display help information.
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

# Ensure the required dependencies are installed
Dependencies "curl"

while [[ "$1" =~ ^(-|--) ]]
do
	case "$1" in
		-b | --bat )
			shift
			BATTERY="${1:?'ERROR: Missing battery device'}"
			;;

		-c | --cfg )
			shift
			CFG_FILE="${1:?'ERROR: Missing configuration file'}"
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

	# Discard option after processing it
	shift
done

# Validate configuration file parameters
if [[ -r "${CFG_FILE:?'ERROR: Configuration file not set'}" ]]
then
	# Configuration file must contain:
	#	token	- Telegram bot token
	#	chatid	- Telegram group chat id
	#	log 	- Log file
	#	limit	- Auto shutdown when battery is under this percentage
	source "$CFG_FILE"

	if [[ -z "${token}" || -z "${chatid}" || -z "${log}" || -z "${limit}" ]]
	then
		echo "ERROR: Missing required configuration parameters" >&2
		exit 1
	fi
else
	echo "ERROR: Unable to find/read configuration file" >&2
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

	[[ ! -e "${log}" ]] && touch "${log}"

	echo "$(date +"[%Y-%m-%d %H:%M:%S]") ${MSG}" >> "${log}" && return 0
}

# Function for sending Telegram alerts
sendAlert() {
	local MSG RESPONSE

	# expected positional argument check and message composition
	read -r -d '' MSG <<- EOF
	<b>$(hostname)</b>  <i>@$(date +"%Y-%m-%d %H:%M:%S")</i>
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
[[ -r /tmp/pwrsply ]] && source /tmp/pwrsply

if [[ -z "${PWRSPLY+x}" ]]
then
	echo "PWRSPLY=0" > /tmp/pwrsply
	[[ -r /tmp/pwrsply ]] && source /tmp/pwrsply
fi

# Evaluates current host power state
case "${STATUS:?'WARN: Status not set'}" in
	Full )
		if (( $PWRSPLY > 0 ))
		then
			logger "[On AC power] Battery is fully charged"
			sendAlert "&#9889; [On AC power] Battery is fully charged"
		fi

		echo "PWRSPLY=0" > /tmp/pwrsply
		exit 0
		;;
	Charging )
		logger "[On AC power] Battery is charging ( ${CHARGE:-###}% )"

		if (( $PWRSPLY > 1 ))
		then
			sendAlert "&#128268; [On AC power] Battery is charging ( ${CHARGE:-###}% )"
		fi

		echo "PWRSPLY=1" > /tmp/pwrsply
		exit 0
		;;
	Discharging )
		logger "[On battery power] Battery is discharging ( ${CHARGE:-###}% )"

		if (( ${CHARGE:-100} <= $limit ))
		then
			logger "[Shutdown] The system will be shutdown to reserve battery for disaster prevention"
			sendAlert "&#128680; [Shutdown] The system will be shutdown to reserve battery for disaster prevention"

			# Machine will be shutdown after one minute
			shutdown -P +1
		fi

		if (( $PWRSPLY < 2 ))
		then
			sendAlert "&#128267; [On Battery power] Battery is discharging ( ${CHARGE:-###}% )"
		fi

		echo "PWRSPLY=2" > /tmp/pwrsply
		exit 0
		;;
	* ) # DEFAULT
		logger "[Action required] Unknown power state ( ${STATUS:-???} @ ${CHARGE:-###}% )"

		if (( $PWRSPLY != 3 ))
		then
			sendAlert "&#10071; [Action required] Unknown power state ( ${STATUS:-???} @ ${CHARGE:-###}% )"
		fi

		echo "PWRSPLY=3" > /tmp/pwrsply
		exit 1
		;;
esac
