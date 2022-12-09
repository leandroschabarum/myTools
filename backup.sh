#!/bin/bash

################ BACKUP SCRIPT ################
# Created: Dec, 2022
# Creator: Leandro Schabarum
# Contact: leandroschabarum.98@gmail.com
###############################################
# Exit codes:
# 0 - Successfully executed script
# 1 - Execution failed (Generic)
# 2 - Missing required dependencies
###############################################

Help() {
	cat <<- EOF >&1
	$(basename "$0") [OPTIONS] SOURCES
	Script for automating backup routines.

	-o <output>  (required)  Backup output destination.
	-h           (optional)  Displays help information.
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
Dependencies "rsync"

# Process user input when running script
while getopts 'o:h' OPT
do
	case "${OPT}" in
		o ) # Output destination target
			TARGET="${OPTARG:?'ERROR: Missing backup output destination'}"
			# Discard option value after processing it
			shift
			;;

		h ) # Displays help information
			Help
			exit 0
			;;

		\? ) # Invalid option
			echo "ERROR: Invalid script option" >&2
			Help
			exit 1
			;;
	esac

	# Discard option name after processing it
	shift
done

# Ensure default values after processing input
RSYNC=$(which rsync)
RSYNC=${RSYNC:?'ERROR: Missing rsync utility'}
TARGET="${TARGET:?'ERROR: Missing backup destination target'}"
SOURCES="${*:?'ERROR: Missing source files'}"

TARGET="${TARGET%%/}" # Removes trailing slashes
DATE="$(date +'%F-%R')" # Equivalent to date +'%Y-%m-%d_%H:%M'

#$RSYNC -arbv --backup-dir=.old/$DATE --delete $SOURCES $TARGET >> "$DATE.log"
$RSYNC -arb --backup-dir=.old/$DATE --delete $SOURCES $TARGET

exit 0
