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
	declare -gA _AL_CO_ACTIONS=()
	return 0
}

function al_def_action {
	local name="$1"
	local fct="$2"
	[[ -n $fct ]] || fct="$name"
	_AL_ACTION_FCT+=("$name" "$fct")
	return 0
}

function _al_check_actions {
	for a in "$@" ; do
		ar_contains "$a" "${!_AL_ACTION_FCT[@]}" || \
			lg_error "Unknown action \"$a\"."
	done
	return 0
}

function al_def_actions_order {
	declare -a order=("$@")
	_al_check_actions "${order[@]}"
	_AL_ACTIONS_ORDER=("${order[@]}")
	return 0
}

function al_def_co_actions {
	local action="$1"
	shift
	declare -a coactions=("$@")
	_al_check_actions "$action" "${coactions[@]}"
	_AL_CO_ACTIONS+=("$action" "${coactions[*]}")
	return 0
}

function al_run_actions {

	declare -a actions=("$@")
	_al_check_actions "${actions[@]}"

	# Add co-actions
	for a in "${actions[@]}" ; do
		for coa in ${_AL_CO_ACTIONS[$a]} ; do
			ar_contains "$coa" "${actions[@]}" || actions+=("$coa")
		done
	done

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
		${_AL_ACTION_FCT[$a]}
		status=$?
		[[ $status -eq 0 ]] || \
			lg_error "Action \"$a\" failed with status $status."
	done

	return 0
}

al_reset
