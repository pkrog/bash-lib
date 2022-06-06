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
	declare -ga _AL_ACTIONS_ORDER=()
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

	declare -a order=("$@")

	# Check actions
	for a in "${order[@]}" ; do
		[[ " ${!_AL_ACTION_FCT[@]} " == *" $a "* ]] || \
			lg_error "Unknown action \"$a\"."
	done

	# Set order
	_AL_ACTIONS_ORDER=("${order[@]}")

	return 0
}

function al_run_actions {

	declare -a actions=("$@")
	local retval=0

	# Order actions
	declare -a reordered=()
	for a in "${_AL_ACTIONS_ORDER[@]}" ; do # Put ordered actions first
		[[ " ${actions[@]} " == *" $a "* ]] && reordered+=($a)
	done
	for a in "${actions[@]}" ; do # Put all other actions
		[[ " ${reordered[@]} " != *" $a "* ]] && reordered+=($a)
	done
	actions=("${reordered[@]}")

	# Loop on all actions in order
	for a in "${actions[@]}" ; do
		ar_contains "$a" "${!_AL_ACTION_FCT[@]}" || \
			lg_error "Action \"$a\" is unknown."
		${_AL_ACTION_FCT[$a]}
		retval=$?
		[[ $retval -eq 0 ]] || break
	done

	return $retval
}

al_reset
