# The name/prefix of this module is AR (ARray):
#   "ar_"  for the public functions.
#   "AR_"  for the public global variables or constants.
#   "_ar_" for the private functions.
#   "_AR_" for the private global variables or constants.

# Include guard
if [[ -z $_BASH_LIB_EMBEDDED ]] ; then
	[[ -z $_AR_SOURCED ]] || return 0
	_AR_SOURCED=1
fi

## Test if a value is inside a list of values
function ar_contains {

	local value="$1"
	shift

	for v in "$@" ; do
		[[ "$v" == "$value" ]] && return 0
	done

	return 1
}
