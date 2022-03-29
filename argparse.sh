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

source "$(dirname $BASH_SOURCE)/logging.sh"

function ap_reset_args {

	declare -g  _AP_SCRIPT_NAME=$(basename "$0")
	declare -g  _AP_SCRIPT_VERSION=$VERSION
	declare -g  _AP_SCRIPT_SHORT_DESC=
	declare -g  _AP_SCRIPT_LONG_DESC=
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
}


function ap_set_short_description {
	_AP_SCRIPT_SHORT_DESC="$*"
}

function ap_set_long_description {
	_AP_SCRIPT_LONG_DESC="$*"
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
	[[ -n $name ]] || lg_error "No name definition for option."
}

function _ap_define_var_opt {

	local names="$1"
	local var="$2"
	local type="$3"
	local desc="$4"
	local default="$5"
	local value="$6" # For flag type, value to set if flag is enabled.
	                 # For enum, the comma separated list of allowed values.

	declare -g "$var=$default"
	local name=${names%%,*}
	_ap_define_name_and_aliases "$names"
	_AP_OPT_VAR+=("$name" "$var")
	_AP_OPT_DESC+=("$name" "$desc")
	_AP_OPT_TYPE+=("$name" "$type")
	_AP_OPT_DEFAULT+=("$name" "$default")
	_AP_OPT_VALUE+=("$name" "$value")
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

function ap_add_opt_flag {
	# Flag (empty by default and non-empty if set)

	local names="$1"
	local var="$2"
	shift 2
	local desc="$*"

	_ap_define_var_opt "$names" "$var" flag "$desc" ""
}

function ap_add_opt_rflag {
	# Reverse flag (non-empty by default and empty if set)

	local names="$1"
	local var="$2"
	shift 2
	local desc="$*"

	_ap_define_var_opt "$names" "$var" rflag "$desc" 1
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

	local state="Flag is currently"
	if [[ -z $default ]] ; then
		state+=" OFF."
	else
		state+=" ON."
	fi

	_ap_define_var_opt "$name" "$var" flag "$desc $state" "$default"
	_ap_define_var_opt "no-$name" "$var" rflag "$rdesc $state" "$default"
}

function ap_add_opt_sflag {
	# Define a string flag: a flag that sets a specific to string into a
	# variable

	local name="$1"
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

	local name=${names%%,*}
	_ap_define_name_and_aliases "$names"
	_AP_OPT_FCT+=("$name" "$fct")
	_AP_OPT_DESC+=("$name" "$desc")
	_AP_OPT_TYPE+=("$name" "$type")
}

function _ap_print_opt_flags {

	local opt="$1"

	# Write main flag
	echo -n "-"
	[[ ${#opt} -gt 1 ]] && echo -n "-"
	echo -n $opt

	# Write aliases
	for als in ${_AP_OPT_ALIASES[$opt]} ; do
		echo -n ", -"
		[[ ${#als} -gt 1 ]] && echo -n "-"
		echo -n $als
	done
}

function _ap_print_options {

	[[ ${#_AP_OPTS[@]} -eq 0 ]] && return 0

	echo
	echo "Options:"
	options=$(tr " " "\n" <<<${!_AP_OPTS[@]} | sort | tr "\n" " ")
	for opt in $options ; do

		echo # Blank line
		echo -n "$indent" && _ap_print_opt_flags $opt
		type_var=${_AP_OPT_TYPE[$opt]}
		[[ $type_var == str ]] && echo -n " <string>"
		[[ $type_var == int ]] && echo -n " <integer>"
		[[ $type_var == enum ]] && echo -n " <choice>"
		echo

		# Description
		desc=${_AP_OPT_DESC[$opt]}
		if [[ $type_var == enum ]] ; then
			allowed_values="${_AP_OPT_VALUE[$opt]}"
			[[ -z $allowed_values ]] || \
				desc+=" Allowed values are: $allowed_values."
		fi
		default="${_AP_OPT_DEFAULT[$opt]}"
		[[ -z $default ]] || desc+=" Default value is \"$default\"."
		fold -s -w $((80-${#indent}*2)) <<<"$desc" | \
			sed "s/^/$indent$indent/"
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

	local indent="  "

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

	# Options
	_ap_print_options

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

	# TODO Check characters in name
	# TODO Check that npos >= 0
	# TODO Check type (fct, int, ...)
	[[ -z $npos ]] && npos=1
	[[ -z $type ]] && type=str
	[[ -z $optional ]] && optional=0

	# Set positional info
	_AP_POS_DESC+=($desc)
	_AP_POS_VAR+=($name)
	_AP_POS_NVALUES+=($npos)
	_AP_POS_TYPE+=($type)
	_AP_POS_OPTIONAL+=($optional)

	return 0
}

function ap_add_pos_one {

	local var=$1
	shift
	local desc="$*"

	_ap_add_pos $var "$desc" 1 str
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

function ap_read_args {

	local args="$*" # save arguments for debugging purpose

	# Read optional arguments
	while true ; do
		case $1 in
			-?|--*) origopt=$1
				opt=${origopt#--}
				opt=${opt#-}
				[[ -n ${_AP_OPTS[$opt]} || -n ${_AP_ALIAS_TO_NAME[$opt]} ]] || \
					lg_error "Unknown option $opt."
				[[ -z ${_AP_ALIAS_TO_NAME[$opt]} ]] || \
					opt=${_AP_ALIAS_TO_NAME[$opt]}
				var_type=${_AP_OPT_TYPE[$opt]}

				# Function
				if [[ $var_type == fct ]] ; then
					${_AP_OPT_FCT[$opt]} # Call function

				# Incrementing integer
				elif [[ $var_type == inc ]] ; then
					var_name=${_AP_OPT_VAR[$opt]}
					[[ -n $var_name ]] || declare -g "$var_name=0"
					eval "((++$var_name))"

				# Flag
				elif [[ $var_type == flag ]] ; then
					var_name=${_AP_OPT_VAR[$opt]}
					declare -g "$var_name=1"

				# Reverse flag
				elif [[ $var_type == rflag ]] ; then
					var_name=${_AP_OPT_VAR[$opt]}
					declare -g "$var_name="

				# Enumeration
				elif [[ $var_type == enum ]] ; then
					local v="$2"
					shift
					[[ ",${_AP_OPT_VALUE[$opt]}," == *",$v,"* ]] || \
						lg_error "Value \"$v\" is not allowed for option $opt."
					var_name=${_AP_OPT_VAR[$opt]}
					declare -g "$var_name=$v"

				# Integer
				elif [[ $var_type == int ]] ; then
					local v="$2"
					shift
					[[ $v =~ ^-?[0-9]+$ ]] || lg_error "$origopt expects an"\
						"integer value, not \"$v\"."
					var_name=${_AP_OPT_VAR[$opt]}
					declare -g "$var_name=$v"

				# String
				elif [[ $var_type == str ]] ; then
					local v="$2"
					shift
					var_name=${_AP_OPT_VAR[$opt]}
					declare -g "$var_name=$v"

				else
					lg_error "Unknown type $var_type for argument $opt."

				fi
				;;

			# Handled unknown option
			-|--|--*|-?)  lg_error "Illegal option $1." ;;

			# Split short options joined together
			-[^-]*)       split_opt=$(echo $1 | sed 's/^-//' | \
				sed 's/\([a-zA-Z]\)/ -\1/g') ; set -- $1$split_opt "${@:2}" ;;

			# Quit loop for reading remaining arguments as positional arguments
			*) break
		esac
		shift
	done

	# TODO Set default values for optional arguments
	# URGENT

	# Read positional arguments
	for ((i = 0 ; i < ${#_AP_POS_VAR[@]} ; ++i)) ; do

		local var=${_AP_POS_VAR[$i]}
		local nvals=${_AP_POS_NVALUES[$i]}
		local type=${_AP_POS_TYPE[$i]}
		local optional=${_AP_POS_OPTIONAL[$i]}

		# Read one value
		if [[ $nvals == 1 ]] ; then
			declare -g "$var=$1"
			[[ $optional -eq 1 || -n ${!var} ]] || \
				lg_error "You must set a value for positional argument $var."
			shift

		# Read several values into an array
		else
			declare -ga $var
			j=0
			while [[ $1 != '' && ( $nvals == 0 || $j -lt $nvals ) ]] ; do
				eval "$var+=(\"$1\")"
				shift
				((++j))
			done
		fi
	done
	[[ -z "$*" ]] || lg_error "Forbidden remaining arguments: $*."

	# Debug messages
	lg_debug 1 "Arguments: $args"
	for var in ${_AP_OPT_VAR[@]} ${_AP_POS_VAR[@]} ; do
		lg_debug 1 "$var=${!var}"
	done

	return 0
}

ap_reset_args
