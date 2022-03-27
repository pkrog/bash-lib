# The name/prefix of this module is OS (Operating System):
#   "os_"  for the public functions.
#   "OS_"  for the public global variables or constants.
#   "_os_" for the private functions.
#   "_OS_" for the private global variables or constants.

[[ -z $_OS_SOURCED ]] || return 0
_OS_SOURCED=1

source "$(dirname $BASH_SOURCE)/logging.sh"

OS_DRYRUN=

function os_exec {
	# Run a command

	local status=0

	if [[ -z $OS_DRYRUN ]] ; then
		if command -v $1 2>&1 >/dev/null ; then
			"$@"
			status=$?
		else
			lg_error "Command \"$1\" is not available."
		fi
	else
		echo "$*"
	fi

	return $status
}

function os_eval {
	# Use `eval` to run a command

	local status=0

	if [[ -z $OS_DRYRUN ]] ; then
		if command -v $1 2>&1 >/dev/null ; then
			eval "$@"
			status=$?
		else
			lg_error "Command \"$1\" is not available."
		fi
	else
		echo "$*"
	fi

	return $status
}

function os_try_exec {
	if command -v "$1" >/dev/null 2>&1 ; then
		os_exec "$@"
	else
		lg_warning "Command \"$1\" not found."
		return 1
	fi
}

function os_check_commands {

	# Check that all submitted commands are available.
	for cmd in "$@" ; do
		lg_debug 1 "Checking command \"$cmd\"."
		command -v "$cmd" >/dev/null 2>&1 || \
			lg_error "Cannot find command \"$cmd\"."
	done

	return 0
}

function os_get_first_cmd {

	local status=1

	for cmd in "$@" ; do
		if command -v "$cmd" >/dev/null 2>&1 ; then
			echo "$cmd"
			status=0
			break
		fi
	done

	return $status
}

function os_check_one_command {

	os_get_first_cmd "$@" >/dev/null || \
		lg_error "No command available among: $*."

	return 0
}
