# The name/prefix of this module is AL (Action Loop):
#   "al_"  for the public functions.
#   "AL_"  for the public global variables or constants.
#   "_al_" for the private functions.
#   "_AL_" for the private global variables or constants.

# Include guard
if [[ -z $_BASH_LIB_EMBEDDED ]] ; then
	[[ -z $_AL_SOURCED ]] || return 0
	_AL_SOURCED=1
fi

source "$(dirname $BASH_SOURCE)/array.sh"
source "$(dirname $BASH_SOURCE)/logging.sh"

function al_reset {
	declare -gA _AL_ACTION_FCT=()
	return 0
}

function al_def_action {
	local name="$1"
	local fct="$2"
	[[ -n $fct ]] || fct="$name"
	_AL_ACTION_FCT+=("$name" "$fct")
	return 0
}

function al_def_actions_order {
	return 0
}

function al_run_actions {

	local retval=0

	# Loop on all actions in order
	for a in "$@" ; do
		ar_contains "$a" "${!_AL_ACTION_FCT[@]}" || \
			lg_error "Action \"$a\" is unknown."
		${_AL_ACTION_FCT[$a]}
		retval=$?
		[[ $retval -eq 0 ]] || break
	done

	return $retval
}

al_reset
