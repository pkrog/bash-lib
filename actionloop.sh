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

declare -a _AL_ACTIONS=()
