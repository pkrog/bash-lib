# The name/prefix of this module is LG (LoGging):
#   "lg_"  for the public functions.
#   "LG_"  for the public global variables or constants.
#   "_lg_" for the private functions.
#   "_LG_" for the private global variables or constants.

# Include guard
if [[ -z $_BASH_LIB_EMBEDDED ]] ; then
	[[ -z $_LG_SOURCED ]] || return 0
	_LG_SOURCED=1
fi

LG_DEBUG=0
LG_QUIET=
LG_LOG_TO_FILE=
LG_FILE=
LG_FILE_MAX_SIZE=10000 # 10 KiB

function lg_quit {

	local status=$1
	shift
	local msg="$@"

	lg_info "$msg"

	exit $status
}

function _lg_write_in_file {

	local msg="$*"

	local sz=$(stat --printf="%s" "$LG_FILE")
	[[ $sz -le $LG_FILE_MAX_SIZE ]] || rm $LG_FILE
	[[ -n $LG_LOG_TO_FILE && -n $LG_FILE ]] && echo "$msg" >>$LG_FILE
}

function lg_file {

	local msg="$*"

	_lg_write_in_file "[FILE]" "$msg"
}

function lg_error {

	local msg="$@"

	_lg_write_in_file "[ERROR]" "$msg"
	[[ -n $LG_QUIET ]] || echo "[ERROR] $msg" >&2

	exit 1
}

function lg_warning {

	local msg="$@"

	_lg_write_in_file "[WARNING]" "$msg"
	[[ -n $LG_QUIET ]] || echo "[WARNING] $msg" >&2
}

function lg_debug {

	local lvl=$1 ; shift
	local msg="$@"

	[[ $LG_DEBUG -ge $lvl ]] && _lg_write_in_file "[DEBUG]" "$msg"
	[[ -z $LG_QUIET && $LG_DEBUG -ge $lvl ]] && echo "[DEBUG] $msg" >&2
}

function lg_info {

	local msg="$@"

	_lg_write_in_file "[INFO]" "$msg"
	[[ -n $LG_QUIET ]] || echo "[INFO] $msg"
}
