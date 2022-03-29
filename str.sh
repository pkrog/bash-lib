# The name/prefix of this module is ST (STring):
#   "st_"  for the public functions.
#   "ST_"  for the public global variables or constants.
#   "_st_" for the private functions.
#   "_ST_" for the private global variables or constants.

# Include guard
if [[ -z $_BASH_LIB_EMBEDDED ]] ; then
	[[ -z $_ST_SOURCED ]] || return 0
	_ST_SOURCED=1
fi

function st_join {
	# Join multiple strings together using an arbitrary separator.
	# arg1: The separator.
	# Following arguments: strings to join.

	local sep="$1"
	shift

	if [[ ${#sep} -le 1 ]] ; then
		local IFS="$sep"
		echo -n "$*"
	else
		local i=0
		for s in "$@" ; do
			[[ $i -gt 0 ]] && echo -n "$sep"
			echo -n "$s"
			((++i))
		done
	fi
}
