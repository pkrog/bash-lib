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
LG_FILE="$HOME/.$(basename $0).log"
LG_FILE_MAX_SIZE=10000 # 10 KiB
_LG_COLOR=1
_LG_WARNING_COLOR=$'\e[1;35m'
_LG_ERROR_COLOR=$'\e[1;35m'
_LG_DEBUG_COLOR=$'\e[0;33m'
_LG_INFO_COLOR=$'\e[0;32m'

function lg_enable_color {

	local enable="$1"

	if [[ -n $enable ]] ; then
		_LG_COLOR=1
	else
		_LG_COLOR=
	fi

	return 0
}

function lg_set_color {

	declare -l typ="$1"
	declare -l color="$2"
	local color_code

	# Get color code
	case $color in
		black)        color_code='0;30' ;;
		dark_gray)    color_code='1;30' ;;
		red)          color_code='0;31' ;;
		light_red)    color_code='1;31' ;;
		green)        color_code='0;32' ;;
		brown)        color_code='0;33' ;;
		blue)         color_code='0;34' ;;
		purple)       color_code='0;35' ;;
		cyan)         color_code='0;36' ;;
		light_gray)   color_code='0;37' ;;
		light_green)  color_code='1;32' ;;
		yellow)       color_code='1;33' ;;
		light_blue)   color_code='1;34' ;;
		light_purple) color_code='1;35' ;;
		light_cyan)   color_code='1;36' ;;
		white)        color_code='1;37' ;;
		*)            lg_error "Unknown color \"$color\"." ;;
	esac

	# Set to corresponding type
	case $typ in
		info)    _LG_INFO_COLOR=$'\e['$color'm'    ;;
		debug)   _LG_DEBUG_COLOR=$'\e['$color'm'   ;;
		warning) _LG_WARNING_COLOR=$'\e['$color'm' ;;
		error)   _LG_ERROR_COLOR=$'\e['$color'm'   ;;
		*)       lg_error "Unknown message type \"$typ\"." ;;
	esac

	return 0
}

function lg_quit {

	local status=$1
	shift
	local msg="$@"

	lg_info "$msg"

	exit $status
}

function _lg_write_in_file {

	local msg="$*"

	if [[ -f $LG_FILE ]] ; then
		local sz=$(stat --printf="%s" "$LG_FILE")
		[[ $sz -le $LG_FILE_MAX_SIZE ]] || rm $LG_FILE
	fi
	[[ -n $LG_LOG_TO_FILE && -n $LG_FILE ]] && echo "$msg" >>$LG_FILE

	return 0
}

function lg_file {

	local msg="$*"

	_lg_write_in_file "[FILE]" "$msg"

	return 0
}

function lg_error {

	local msg="$@"

	_lg_write_in_file "[ERROR]" "$msg"
	if [[ -z $LG_QUIET ]] ; then
		[[ -z $_LG_COLOR ]] || echo -n $_LG_ERROR_COLOR >&2
		echo -n "[ERROR] $msg" >&2
		[[ -z $_LG_COLOR ]] || echo -n $'\e[0m' >&2
		echo >&2
	fi

	exit 1
}

function lg_warning {

	local msg="$@"

	_lg_write_in_file "[WARNING]" "$msg"
	if [[ -z $LG_QUIET ]] ; then
		[[ -z $_LG_COLOR ]] || echo -n $_LG_WARNING_COLOR >&2
		echo -n "[WARNING] $msg" >&2
		[[ -z $_LG_COLOR ]] || echo -n $'\e[0m' >&2
		echo >&2
	fi

	return 0
}

function lg_debug {

	local lvl=$1 ; shift
	local msg="$@"

	[[ $LG_DEBUG -ge $lvl ]] && _lg_write_in_file "[DEBUG]" "$msg"
	if [[ -z $LG_QUIET && $LG_DEBUG -ge $lvl ]] ; then
		[[ -z $_LG_COLOR ]] || echo -n $_LG_DEBUG_COLOR >&2
		echo -n "[DEBUG] $msg" >&2
		[[ -z $_LG_COLOR ]] || echo -n $'\e[0m' >&2
		echo >&2
	fi
}

function lg_info {

	local msg="$@"

	_lg_write_in_file "[INFO]" "$msg"
	if [[ -z $LG_QUIET ]] ; then
		[[ -z $_LG_COLOR ]] || echo -n $_LG_INFO_COLOR
		echo -n "[INFO] $msg"
		[[ -z $_LG_COLOR ]] || echo -n $'\e[0m'
		echo
	fi

	return 0
}
