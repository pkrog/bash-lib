# The name/prefix of this module is DP (DePrecate):
#   "dp_"  for the public functions.
#   "DP_"  for the public global variables or constants.
#   "_dp_" for the private functions.
#   "_DP_" for the private global variables or constants.

# Include guard
if [[ -z $_BASH_LIB_EMBEDDED ]] ; then
	[[ -z $_DP_SOURCED ]] || return 0
	_DP_SOURCED=1
fi

source "$(dirname $BASH_SOURCE)/logging.sh"

function dp_deprecated {
	local new_fct="$1"
	lg_debug 1 "Deprecated function. Use $new_fct() instead."
}
