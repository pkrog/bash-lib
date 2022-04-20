# The name/prefix of this module is RT (TestThat):
#   "rt_"  for the public functions.
#   "RT_"  for the public global variables or constants.
#   "_rt_" for the private functions.
#   "_RT_" for the private global variables or constants.

# Include guard
if [[ -z $_BASH_LIB_EMBEDDED ]] ; then
	[[ -z $_RT_SOURCED ]] || return 0
	_RT_SOURCED=1
fi

function rt_print_call_stack {

	local frame=0
	while caller $frame >&2 ; do
		((frame++));
	done
}

