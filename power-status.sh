#!/bin/bash

BATTERY="BAT0"
SYS_FILE="/sys/class/power_supply/${BATTERY:?'ERROR: Battery device not set'}"
LOG_FILE="/var/log/power.log"

STATUS="$(cat "${SYS_FILE:?'ERROR: Filesystem dir not set'}/status")"
CHARGE="$(cat "${SYS_FILE:?'ERROR: Filesystem dir not set'}/capacity")"

# Missing

sendAlert() {
	# 'token' and 'chatid' variables come from configuration file
	# in cases when they are not set skip function execution
	[[ -z "${token}" || -z "${chatid}" ]] && return 1

	local MSG RESPONSE
	# expected positional argument check and message composition
	read -r -d '' MSG <<- EOF
	&#10071; <b>[$(hostname)]</b> <i>$(date +"%Y-%m-%d %H:%M:%S")</i>
	${1:?'WARN: Message is required'}
	EOF

	REQUEST_URL="https://api.telegram.org/bot${token}/sendMessage"
	# Telegram API request using curl and grep to retrieve confirmation that message was send successfully
	RESPONSE="$(curl --location --request GET "$REQUEST_URL" \
		--data-urlencode "chat_id=${chatid}" \
		--data-urlencode "parse_mode=HTML" \
		--data-urlencode "text=${MSG:?'ERROR: Empty message'}" \
		2>&1)"

	# if no {"ok":true} response is received, defaults to returning failed notication status
	[[ "$(echo "${RESPONSE:='empty'}" | grep -o -E '"ok":( +)?[[:alnum:]]+[^,]' | cut -d ':' -f 2)" =~ true ]] && return 0
	echo "$(date +"[%Y-%m-%d %H:%M:%S]") Failed to send Telegram notification <${RESPONSE:='empty'}>" >> "${LOG_FILE:?'ERROR: Log file not set'}" && return 1
}

# Evaluates current host power state
case "${STATUS:?'WARN: Status not set'}" in
	Full)
		echo -e "[On AC power] Battery is fully charged."
		exit 0
		;;
	Charging)
		echo -e "[On AC power] Battery is charging ( ${CHARGE:-###}% )"
		sendAlert("[On AC power] Battery is charging ( ${CHARGE:-###}% )")
		exit 0
		;;
	Discharging)
		echo -e "[On Battery power] Battery is discharging ( ${CHARGE:-###}% )"
		sendAlert("[On Battery power] Battery is discharging ( ${CHARGE:-###}% )")
		exit 1
		;;
	*) # DEFAULT
		echo -e "[Action required] Unknown power state"
		sendAlert("[Action required] Unknown power state")
		exit 1
		;;
esac

