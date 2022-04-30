# The name/prefix of this module is OS (Operating System):
#   "os_"  for the public functions.
#   "OS_"  for the public global variables or constants.
#   "_os_" for the private functions.
#   "_OS_" for the private global variables or constants.

# Include guard
if [[ -z $_BASH_LIB_EMBEDDED ]] ; then
	[[ -z $_OS_SOURCED ]] || return 0
	_OS_SOURCED=1
fi

source "$(dirname $BASH_SOURCE)/logging.sh"

OS_DRYRUN=
OS_LOCK_FILE="$HOME/.$(basename $0).lock"
_OS_PRINT_COMMANDS=

function os_enable_cmd_printing {
	_OS_PRINT_COMMANDS=1
	return 0
}

function os_exec {
	# Run a command

	local status=0

	if [[ -z $OS_DRYRUN ]] ; then
		if command -v $1 2>&1 >/dev/null ; then
			[[ -z $_OS_PRINT_COMMANDS ]] || lg_info "Running: $*"
			"$@"
			status=$?
		else
			lg_error "Command \"$1\" is not available."
		fi
	else
		lg_info "Would run: $*"
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

function os_exec_lock {
	# Execute a command only if lock file is available
	local cmd="$1"

	PID=$$
	lg_debug 1 "PID=$PID"

	# Open lock file with file descriptor 9
	exec 9<>$OS_LOCK_FILE

	# Try to lock file descriptor 9
	if flock -n 9 ; then

		# Write PID into lock file
		echo $PID >&9

		# Execute
		"$cmd"

		# Remove lock file
		unlink "$OS_LOCK_FILE"
	else
		running_pid=$(cat "$OS_LOCK_FILE")
		lg_error "Cannot run \"$cmd\", lock file $OS_LOCK_FILE is already"\
			"taken by process $running_pid."
	fi
}

function os_force_remove_lock {

	local kill_cmd="$1"

	if [[ -f $OS_LOCK_FILE ]] ; then
		lg_debug 1 "Removing lock file $OS_LOCK_FILE."
		local running_pid=$(cat "$OS_LOCK_FILE")
		if [[ -n $running_pid ]] ; then

			# Kill running process
			if [[ -n $kill_cmd ]] ; then
				lg_debug 1 "Calling \"$kill_cmd\" to kill processes."
				"$kill_cmd"
			fi

			[[ -f $OS_LOCK_FILE ]] && rm $OS_LOCK_FILE
		fi
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
