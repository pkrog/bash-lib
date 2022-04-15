# The name/prefix of this module is AP (Arguments Parse):
#   "ap_"  for the public functions.
#   "AP_"  for the public global variables or constants.
#   "_ap_" for the private functions.
#   "_AP_" for the private global variables or constants.

# Include guard
if [[ -z $_BASH_LIB_EMBEDDED ]] ; then
	[[ -z $_AP_SOURCED ]] || return 0
	_AP_SOURCED=1
fi

_AP_INDENT="  "

source "$(dirname $BASH_SOURCE)/logging.sh"

function ap_reset_args {

	declare -g  _AP_SCRIPT_NAME=$(basename "$0")
	declare -g  _AP_SCRIPT_VERSION=$VERSION
	declare -g  _AP_SCRIPT_SHORT_DESC=
	declare -g  _AP_SCRIPT_LONG_DESC=
	declare -g  _AP_USE_ENV_VAR=
	declare -gu _AP_ENV_VAR_PREFIX=
	declare -ga _AP_POS_DESC=()
	declare -ga _AP_POS_VAR=()
	declare -ga _AP_POS_NVALUES=()
	declare -ga _AP_POS_TYPE=()
	declare -gA _AP_OPTS=()
	declare -gA _AP_ALIAS_TO_NAME=()
	declare -gA _AP_OPT_ALIASES=()
	declare -gA _AP_OPT_VAR=()
	declare -gA _AP_OPT_FCT=()
	declare -gA _AP_OPT_DESC=()
	declare -gA _AP_OPT_TYPE=()
	declare -gA _AP_OPT_DEFAULT=()
	declare -gA _AP_OPT_VALUE=()
	declare -gA _AP_OPT_NMIN=() # Minimum number of times to set the option.
	declare -gA _AP_OPT_NMAX=() # Maximum number of times to set the option.
	declare -gA _AP_OPT_NTIMES=() # Number of times the option has been
	                              # actually defined.
	declare -gA _AP_OPT_ENV_VAR=()
}


function ap_set_short_description {
	_AP_SCRIPT_SHORT_DESC="$*"
}

function ap_set_long_description {
	_AP_SCRIPT_LONG_DESC="$*"
}

function ap_use_env_var {
	# Enable use of environment variables to set arguments.

	local prefix="$1"

	if [[ -n $prefix ]] ; then
		_AP_ENV_VAR_PREFIX="$prefix"
	else
		_AP_ENV_VAR_PREFIX="$_AP_SCRIPT_NAME"
		_AP_ENV_VAR_PREFIX=$(echo $_AP_ENV_VAR_PREFIX | sed 's/[^A-Z_]/_/g')
	fi

	[[ $s =~ [^A-Z_] ]] && lg_error "Prefix for environment variables must"\
		"contain only '_' or upper ascii letters."
	
	_AP_USE_ENV_VAR=1
}

function _ap_get_env_var_name {

	local var="$1"

	declare -u envvar="${_AP_ENV_VAR_PREFIX}_$var"
	echo "$envvar"
}

function _ap_define_name_and_aliases {

	local names="$1"

	# Parse main name and declare aliases
	local i=0
	local name=
	local oldifs="$IFS"
	IFS=,
	for n in $names ; do
		if [[ $i -eq 0 ]] ; then
			name=$n
			_AP_OPTS+=($n 1)
		else
			_AP_ALIAS_TO_NAME+=($n $name)
			_AP_OPT_ALIASES+=($name "${_AP_OPT_ALIASES[$name]} $n")
		fi
		((++i))
	done
	IFS="$oldifs"
	[[ -n $name ]] || lg_error "No name definition for option (received"\
		"names=\"$names\")."
}

function _ap_define_var_opt {

	local names="$1"
	local var="$2"
	local type="$3"
	local desc="$4"
	local default="$5"
	local value="$6" # For flag type, value to set if flag is enabled.
	                 # For enum, the comma separated list of allowed values.
	local nmin="$7"  # Minimum of times to set the opt
	local nmax="$8"  # Maximum of times to set the opt
	local name=${names%%,*}

	# Default value
	[[ -z $nmin ]] && nmin=0
	[[ -z $nmax ]] && nmax=1

	lg_debug 1 "Defining option type=$type, var=$var, names=$names."
	# Use env var
	if [[ -n $_AP_USE_ENV_VAR ]] ; then
		local envvar=$(_ap_get_env_var_name "$var")
		_AP_OPT_ENV_VAR+=("$name" "$envvar")
		[[ ! ${!envvar} ]] || default=${!envvar}
	fi

	declare -g "$var=$default"
	_ap_define_name_and_aliases "$names"
	_AP_OPT_VAR+=("$name" "$var")
	_AP_OPT_DESC+=("$name" "$desc")
	_AP_OPT_TYPE+=("$name" "$type")
	_AP_OPT_DEFAULT+=("$name" "$default")
	_AP_OPT_VALUE+=("$name" "$value")
	_AP_OPT_NMIN+=("$name" $nmin)
	_AP_OPT_NMAX+=("$name" $nmax)
	_AP_OPT_NTIMES+=("$name" 0)
}

function ap_add_opt_int {

	local names="$1"
	local var="$2"
	local default="$3"
	shift 3
	local desc="$*"

	_ap_define_var_opt "$names" "$var" int "$desc" "$default"
}

function ap_add_opt_enum {
	# Define enumeration option.

	local names="$1"
	local var="$2"
	local values="$3" # List of allowed values. The first one is the default.
	shift 3
	local desc="$*"
	local default=${values%%,*}

	_ap_define_var_opt "$names" "$var" enum "$desc" "$default" "$values"
}

function ap_add_opt_str {

	local names="$1"
	local var="$2"
	local default="$3"
	shift 3
	local desc="$*"

	_ap_define_var_opt "$names" "$var" str "$desc" "$default"
}

function ap_add_opt_str_mult {

	local names="$1"
	local var="$2"
	shift 2
	local desc="$*"

	_ap_define_var_opt "$names" "$var" str "$desc" "$default" "" 0 0
}

function ap_add_opt_flag {
	# Flag (empty by default and non-empty if set)

	local names="$1"
	local var="$2"
	shift 2
	local desc="$*"

	_ap_define_var_opt "$names" "$var" flag "$desc" "" 1
}

function ap_add_opt_rflag {
	# Reverse flag (non-empty by default and empty if set)

	local names="$1"
	local var="$2"
	shift 2
	local desc="$*"

	_ap_define_var_opt "$names" "$var" rflag "$desc" 1 ""
}

function ap_add_opt_oflags {
	# Define opposite flags (--foo and --no-foo)

	local name="$1"
	local var="$2"
	local default="$3"
	local desc="$4"
	local rdesc="$5"

	# Check the name
	[[ $name =~ , ]] && lg_error "In order to define opposite flags, you need"\
		"to provide only one name. You provided \"$name\"."

	_ap_define_var_opt "$name" "$var" flag "$desc $state" "$default" 1
	_ap_define_var_opt "no-$name" "$var" rflag "$rdesc $state" "$default" ""
}

function ap_add_opt_sflag {
	# Define a string flag: a flag that sets a specific string into a
	# variable

	local names="$1"
	local var="$2"
	local value="$3"
	shift 3
	local desc="$*"

	_ap_define_var_opt "$names" "$var" flag "$desc" "" "$value"
}

function ap_add_opt_inc {

	local names="$1"
	local var="$2"
	shift 2
	local desc="$*"

	_ap_define_var_opt "$names" "$var" inc "$desc"
}

function ap_add_opt_fct {

	local names="$1"
	local fct="$2"
	shift 2
	local desc="$*"
	local type=fct
	lg_debug 1 "Defining option type=$type, fct=$fct, names=$names."

	local name=${names%%,*}
	_ap_define_name_and_aliases "$names"
	_AP_OPT_FCT+=("$name" "$fct")
	_AP_OPT_DESC+=("$name" "$desc")
	_AP_OPT_TYPE+=("$name" "$type")
}

function _ap_get_full_opt_flag {

	local opt="$1"

	echo -n "-"
	[[ ${#opt} -gt 1 ]] && echo -n "-"
	echo -n $opt
}

function _ap_print_opt_flags {

	local opt="$1"

	# Write main flag
	echo $(_ap_get_full_opt_flag "$opt")

	# Write aliases
	for als in ${_AP_OPT_ALIASES[$opt]} ; do
		echo -n ", "$(_ap_get_full_opt_flag "$als")
	done
}

function _ap_print_type {

	local type="$1"

	case $type in
		str) echo -n " <string>" ;;
		int) echo -n " <integer>" ;;
		enum) echo -n " <choice>" ;;
	esac
}

function _ap_print_arg_desc {

	local desc="$1"

	sed 's/  \+/ /g' <<<"$desc" | fold -s -w $((80-${#_AP_INDENT}*2)) | \
		sed "s/^/$_AP_INDENT$_AP_INDENT/"
}

function _ap_print_pos_args {

	[[ ${#_AP_POS_VAR[@]} -eq 0 ]] && return 0

	echo
	echo "Positional arguments:"
	for ((i = 0 ; i < ${#_AP_POS_VAR[@]} ; ++i)) ; do

		echo # Blank line
		echo -n "$_AP_INDENT${_AP_POS_VAR[$i]}"
		_ap_print_type "${_AP_POS_TYPE[$i]}"
		echo

		_ap_print_arg_desc "${_AP_POS_DESC[$i]}"
	done
}

function _ap_print_opt_args {

	[[ ${#_AP_OPTS[@]} -eq 0 ]] && return 0

	echo
	echo "Optional arguments:"
	options=$(tr " " "\n" <<<${!_AP_OPTS[@]} | sort | tr "\n" " ")
	for opt in $options ; do

		echo # Blank line
		echo -n "$_AP_INDENT"
		_ap_print_opt_flags $opt
		type_var=${_AP_OPT_TYPE[$opt]}
		_ap_print_type "$type_var"
		echo

		# Description
		desc=${_AP_OPT_DESC[$opt]}
		if [[ $type_var == enum ]] ; then
			allowed_values="${_AP_OPT_VALUE[$opt]}"
			[[ -z $allowed_values ]] || \
				desc+=" Allowed values are: $allowed_values."
		fi
		default="${_AP_OPT_DEFAULT[$opt]}"
		case $type_var in
			flag) if [[ -z $default ]] ; then desc+=" Disabled by default." ; \
				else desc+=" Enabled by default." ; fi ;;
			rflag) ;;
			*) [[ -z $default ]] || desc+=" Default value is \"$default\"." ;;
		esac
		envvar="${_AP_OPT_ENV_VAR[$opt]}"
		[[ -z $envvar ]] || \
			desc+=" Can be set with environment variable $envvar."
		_ap_print_arg_desc "$desc"
	done
}

function _ap_print_usage {

	# Blank line
	echo

	# Title and script name
	echo -n "Usage: $_AP_SCRIPT_NAME"

	# Options
	[[ ${#_AP_OPTS[@]} -gt 0 ]] && echo -n " [options]"

	# Position arguments
	for pos in ${_AP_POS_VAR[@]} ; do
		echo -n " $pos"
	done

	# New line
	echo
}

function ap_print_version {
	if [[ -n $_AP_SCRIPT_VERSION ]] ; then
		echo "$_AP_SCRIPT_VERSION"
	else
		echo "Unknown version."
	fi
	exit 0
}

function ap_print_help {

	# First line
	echo -n "$_AP_SCRIPT_NAME"
	[[ -z $_AP_SCRIPT_VERSION ]] || echo -n ", version $_AP_SCRIPT_VERSION"
	[[ -z $_AP_SCRIPT_SHORT_DESC ]] || echo -n ", $_AP_SCRIPT_SHORT_DESC"
	echo "."

	# Long description
	if [[ -n $_AP_SCRIPT_LONG_DESC ]] ; then
		echo
		echo "$_AP_SCRIPT_LONG_DESC"
	fi

	# Usage
	_ap_print_usage

	# Positional arguments
	_ap_print_pos_args

	# Optional arguments
	_ap_print_opt_args

	echo
	exit 0
}

function ap_add_debug_opt {
	ap_add_opt_inc "g,debug" LG_DEBUG "Debug mode."
}

function ap_add_quiet_opt {
	ap_add_opt_flag "q,quiet" LG_QUIET "Turn off all messages from logging"\
		"library."
}

function ap_add_log_opt {
	ap_add_opt_flag "l,log" LG_LOG_TO_FILE "Enable logging to file."
}

function ap_add_log_file_opt {
	ap_add_opt_str "log-file" LG_FILE "$HOME/.$_AP_SCRIPT_NAME.log" \
		"Set the file to use for logging."
}

function ap_add_log_file_size_opt {
	ap_add_opt_int "log-file-size" LG_FILE_MAX_SIZE 10000 \
		"Set the maximum size of the log file."
}

function ap_add_lock_file_opt {
	ap_add_opt_str "lock-file" OS_LOCK_FILE "$HOME/.$_AP_SCRIPT_NAME.lock" \
		"Set the file to use for locking application."
}

function ap_add_dryrun_opt {
	ap_add_opt_flag "dryrun,dry-run" OS_DRYRUN "Display what would be run,"\
		"but do not execute anything."
}

function ap_add_help_opt {
	ap_add_opt_fct "h,help" ap_print_help "Print a help message and exit."
}

function ap_add_version_opt {
	ap_add_opt_fct "v,version" ap_print_version "Print the version and exit."
}

function _ap_add_pos {

	local name="$1"
	local desc="$2"
	local npos="$3"
	local type="$4"
	local optional="$5"
	local values="$6"

	# TODO Check characters in name
	# TODO Check that npos >= 0
	# TODO Check type (fct, int, ...)
	[[ -z $npos ]] && npos=1
	[[ -z $type ]] && type=str
	[[ -z $optional ]] && optional=0

	# Set positional info
	_AP_POS_DESC+=("$desc")
	_AP_POS_VAR+=("$name")
	_AP_POS_NVALUES+=("$npos")
	_AP_POS_TYPE+=("$type")
	_AP_POS_OPTIONAL+=("$optional")
	_AP_POS_VALUES+=("$values")

	return 0
}

function ap_add_pos_one {

	local var=$1
	shift
	local desc="$*"

	_ap_add_pos "$var" "$desc" 1 str
}

function ap_add_pos_one_enum {

	local var="$1"
	local values="$2"
	shift 2
	local desc="$*"

	_ap_add_pos "$var" "$desc" 1 enum 0 "$values"
}

function ap_add_pos_one_optional {

	local var=$1
	shift
	local desc="$*"

	_ap_add_pos $var "$desc" 1 str 1
}

function ap_add_pos_n {

	local var=$1
	local n=$2
	shift 2
	local desc="$*"

	_ap_add_pos $var "$desc" $n str
}

function ap_add_pos_max {

	local var=$1
	shift
	local desc="$*"

	_ap_add_pos $var "$desc" 0 str
}

function ap_add_pos_max_enum {

	local var=$1
	local values="$2"
	shift 2
	local desc="$*"

	_ap_add_pos $var "$desc" 0 enum 0 "$values"
}

function _ap_check_enum_value {

	local v="$1"
	local values="$2"

	lg_debug 1 "Check if \"$v\" is in \"$values\"."
	[[ ",$values," == *",$v,"* ]]
	local status=$?
	lg_debug 1 "status=$status."

	return $status
}

function _ap_process_opt {

	local nshift=0
	local origopt="$1"

	# Get option name
	local opt=${origopt#--}
	opt=${opt#-}
	[[ -n ${_AP_OPTS[$opt]} || -n ${_AP_ALIAS_TO_NAME[$opt]} ]] || \
		return $nshift
	[[ -z ${_AP_ALIAS_TO_NAME[$opt]} ]] || opt=${_AP_ALIAS_TO_NAME[$opt]}

	# Get option type
	local var_type=${_AP_OPT_TYPE[$opt]}

	# Function
	if [[ $var_type == fct ]] ; then
		nshift=1
		${_AP_OPT_FCT[$opt]} # Call function

	# Incrementing integer
	elif [[ $var_type == inc ]] ; then
		nshift=1
		local var_name=${_AP_OPT_VAR[$opt]}
		[[ -n $var_name ]] || declare -g "$var_name=0"
		eval "((++$var_name))"

	# Flag
	elif [[ $var_type == flag || $var_type == rflag ]] ; then
		nshift=1
		declare -g "${_AP_OPT_VAR[$opt]}=${_AP_OPT_VALUE[$opt]}"

	# Enumeration
	elif [[ $var_type == enum ]] ; then
		local v="$2"
		nshift=2
		_ap_check_enum_value "$v" "${_AP_OPT_VALUE[$opt]}" || \
			lg_error "Value \"$v\" is not allowed for option $opt."
		local var_name=${_AP_OPT_VAR[$opt]}
		declare -g "$var_name=$v"

	# Integer
	elif [[ $var_type == int ]] ; then
		local v="$2"
		nshift=2
		[[ $v =~ ^-?[0-9]+$ ]] || lg_error "$origopt expects an"\
			"integer value, not \"$v\"."
		local var_name=${_AP_OPT_VAR[$opt]}
		declare -g "$var_name=$v"

	# String
	elif [[ $var_type == str ]] ; then
		local v="$2"
		nshift=2

		# Get var name
		local var_name=${_AP_OPT_VAR[$opt]}

		# Define variable
		if [[ ${_AP_OPT_NTIMES[$opt]} -eq 0 ]] ; then
			if [[ ${_AP_OPT_NMAX[$opt]} -eq 1 ]] ; then
				declare -g "$var_name="
			else
				declare -ga "$var_name=()"
			fi
		fi

		# Set value
		if [[ ${_AP_OPT_NMAX[$opt]} -eq 1 ]] ; then
			eval "$var_name=$v"
		else
			eval "$var_name+=(\"$v\")"
		fi

		# Increment counter
		eval "_AP_OPT_NTIMES+=(\"$opt\" \$((${_AP_OPT_NTIMES[$opt]} + 1)))"

		[[ ${_AP_OPT_NMAX[$opt]} -eq 0 || \
			${_AP_OPT_NTIMES[$opt]} -le ${_AP_OPT_NMAX[$opt]} ]] || \
			lg_error "You have used too many times the option '$opt'."
	else
		lg_error "Unknown type $var_type for argument "\
			$(_ap_get_full_opt_flag "$opt")"."

	fi

	return $nshift
}

function _ap_print_debug_msgs {

	local args="$1"

	lg_debug 1 "Arguments: $args"

	# Print variables of optional arguments
	local vars=$(tr " " "\n" <<< "${_AP_OPT_VAR[@]}" | sort | uniq)
	for var in $vars ; do
		lg_debug 1 "$var=${!var}"
	done

	# Print variables of  positional arguments
	local vars=$(tr " " "\n" <<< "${_AP_POS_VAR[@]}" | sort | uniq)
	for var in $vars ; do
		eval "lg_debug 1 \"$var=\${$var[@]}\""
	done

	return 0
}

function _ap_read_pos_args {

	for ((i = 0 ; i < ${#_AP_POS_VAR[@]} ; ++i)) ; do

		local var=${_AP_POS_VAR[$i]}
		local nvals=${_AP_POS_NVALUES[$i]}
		local type=${_AP_POS_TYPE[$i]}
		local optional=${_AP_POS_OPTIONAL[$i]}
		local values=${_AP_POS_VALUES[$i]}

		# Read values
		if [[ $nvals -eq 1 ]] ; then
			declare -g "$var="
		else
			declare -ga "$var=()"
		fi
		local j=0
		lg_debug 1 "var=$var"
		lg_debug 1 "type=$type"
		lg_debug 1 "nvals=$nvals"
		while [[ $1 != '' && ( $nvals -eq 0 || $j -lt $nvals ) ]] ; do

			lg_debug 1 "j=$j"
			# Check enum value
			if [[ $type == enum ]] \
				&& ! _ap_check_enum_value "$1" "$values" ; then
				[[ $nvals == 0 ]] && break
				lg_error "Value \"$1\" is not allowed for positional argument"\
				"$var."
			fi

			# Set value
			if [[ $nvals -eq 1 ]] ; then
				eval "$var=$1"
			else
				eval "$var+=(\"$1\")"
			fi

			# Pass to next value
			shift
			((++j))
		done

		# Check number of read values
		if [[ $optional -eq 0 && $nvals -gt 0 && $j -lt $nvals ]] ; then
			if [[ $nvals -eq 1 ]] ; then
				lg_error "You must set a value for positional argument $var."
			else
				lg_error "You must set $nvals values for positional argument"\
					"$var."
			fi
		fi
	done
	[[ -z "$*" ]] || lg_error "Forbidden remaining arguments: $*."
}

function ap_read_args {

	local args="$*" # save arguments for debugging purpose

	# Read optional arguments
	while true ; do
		lg_debug 1 "Left options: $*"
		case $1 in

			# Try to process this option
			-?|--*) _ap_process_opt "$@"
				local nshift=$? # Status is the number of shifts to apply
				[[ $nshift -gt 0 ]] && shift $nshift && continue
				;;& # Go on to next case

			# Handled unknown option
			-|--|--*|-?) lg_error "Illegal option $1." ;;

			# Split short options joined together
			-[^-]*) split_opt=$(echo $1 | sed 's/^-//' | \
				sed 's/\([a-zA-Z]\)/ -\1/g') ; set -- $1$split_opt "${@:2}" ; shift ;;

			# Quit loop for reading remaining arguments as positional arguments
			*) break
		esac
	done

	# Read positional arguments
	_ap_read_pos_args "$@"

	# Debug messages
	_ap_print_debug_msgs "$args"

	return 0
}

ap_reset_args
