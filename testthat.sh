# The name/prefix of this module is TT (TestThat):
#   "tt_"  for the public functions.
#   "TT_"  for the public global variables or constants.
#   "_tt_" for the private functions.
#   "_TT_" for the private global variables or constants.

# Include guard
if [[ -z $_BASH_LIB_EMBEDDED ]] ; then
	[[ -z $_TT_SOURCED ]] || return 0
	_TT_SOURCED=1
fi

source "$(dirname $BASH_SOURCE)/array.sh"
source "$(dirname $BASH_SOURCE)/logging.sh"
source "$(dirname $BASH_SOURCE)/runtime.sh"
source "$(dirname $BASH_SOURCE)/textfile.sh"

TT_REPORT_ON_THE_SPOT=on.the.spot
TT_REPORT_AT_THE_END=at.the.end
_TT_REPORTER=$TT_REPORT_AT_THE_END
_TT_DEFAULT_FILE_PATTERN='[Tt][Ee][Ss][Tt][-._].*\.sh'
_TT_DEFAULT_FCT_PREFIX='[Tt][Ee][Ss][Tt]_\?'
_TT_LIVE_PRINTING=
_TT_QUIT_ON_FIRST_ERROR=
_TT_ERR_NUMBER=0

declare -a _TT_ERR_MSGS=()
declare -a _TT_ERR_STDERR_FILES=()
declare -a _TT_FCTS_RUN_IN_TEST_FILE=()
declare -a _TT_CONTEXTS=()

function tt_get_default_file_pattern {
	echo "$_TT_DEFAULT_FILE_PATTERN"
	return 0
}

function tt_get_default_fct_prefix {
	echo "$_TT_DEFAULT_FCT_PREFIX"
	return 0
}

function tt_get_reporter {
	echo "$_TT_REPORTER"
	return 0
}

function tt_enable_live_printing {
	_TT_LIVE_PRINTING=1
	return 0
}

function tt_enable_quit_on_first_error {
	_TT_QUIT_ON_FIRST_ERROR=1
	return 0
}

## Sets the reporter to use.
function tt_set_reporter {

	local reporter="$1"

	ar_contains "$reporter" "$TT_REPORT_ON_THE_SPOT" "$TT_REPORT_AT_THE_END" ||
		lg_error "The reporter must be one of $TT_REPORT_ON_THE_SPOT or"\
		"$TT_REPORT_AT_THE_END."

	_TT_REPORTER="$reporter"

	return 0
}

function tt_context {

	local msg=$1

	# Is this a new context?
	[[ ${_TT_CONTEXTS[@]} == $msg ]] && return 0

	# Print new line if this is not first context
	[[ ${#_TT_CONTEXTS[@]} -gt 0 ]] && echo

	# Print context
	echo -n "$msg "

	# Store context
	_TT_CONTEXTS+=("$msg")

	return 0
}

function _tt_print_error {
	n=$1
	msg="$2"
	output_file="$3"

	echo
	echo '----------------------------------------------------------------'
	printf "%x. " $n
	echo "Failure while asserting that \"$msg\"."
	echo '---'
	if [[ -f $output_file ]] ; then
		cat "$output_file"
		rm "$output_file"
	fi
	echo '----------------------------------------------------------------'

	return 0
}

tt_finalize_tests() {

	# Print new line
	[[ ${#_TT_CONTEXTS[@]} -eq 0 ]] || echo

	# Print end report
	[[ $_TT_REPORTER == $TT_REPORT_AT_THE_END ]] && _tt_print_end_report

	# Exit
	return $_TT_ERR_NUMBER
}

function _tt_fct_is_allowed {

	local fct="$1" # Function
	local inc_fcts="$2" # Functions to include
	local exc_fcts="$3" # Functions to exclude

	[[ -n $inc_fcts && ",$inc_fcts," != *",$test_fct,"* ]] && return 1
	[[ -n $exc_fcts && ",$exc_fcts," == *",$test_fct,"* ]] && return 1

	return 0
}

function tt_test_that {

	local msg="$1"
	local test_fct="$2"
	local inc_fcts="$3" # Functions to include
	local exc_fcts="$4" # Functions to exclude
	shift 4
	local params="$*"
	local tmp_stderr_file=$(mktemp -t testthat-stderr.XXXXXX)

	# Set default values
	[[ -n $msg ]] || msg="Tests pass in function $test_fct"

	# Filtering
	_tt_fct_is_allowed "$test_fct" "$inc_fcts" "$exc_fcts" || return 0

	# Checking
	local fct_type=$(type -t "$test_fct")
	[[ $fct_type == function || $fct_type == file ]] || lg_error \
		"\"$test_fct\" is neither a function nor an external command."

	# Run test
	_TT_FCTS_RUN_IN_TEST_FILE+=("$test_fct")
	lg_debug 1 "Running test function \"$test_fct\" and redirecting error"\
		"messages to \"$tmp_stderr_file\"."
	( $test_fct $params 2>"$tmp_stderr_file" ) # Run in a subshell to catch exit
	                                           # interruptions.
	exit_code=$?
	lg_debug 1 "Exit code of \"$test_fct\" was $exit_code."

	# Print stderr now
	[[ -n $_TT_LIVE_PRINTING && -f $tmp_stderr_file ]] && cat $tmp_stderr_file

	# Failure
	if [ $exit_code -gt 0 ] ; then

		# Increment error number
		((++_TT_ERR_NUMBER))

		# Print error number
		if [[ _TT_ERR_NUMBER -lt 16 ]] ; then
			printf %x $_TT_ERR_NUMBER
		else
			echo -n E
		fi

		# Print error now
		if [[ $_TT_REPORTER == $TT_REPORT_ON_THE_SPOT ]] ; then
			_tt_print_error $_TT_ERR_NUMBER "$msg" "$tmp_stderr_file"

		# Store error message for later
		else
			_TT_ERR_MSGS+=("$msg")
			_TT_ERR_STDERR_FILES+=("$tmp_stderr_file")
		fi

		# Quit on first error
		[[ -z $_TT_QUIT_ON_FIRST_ERROR ]] || tt_finalize_tests || exit $?

	# Success
	else
		rm $tmp_stderr_file
	fi
}

function tt_run_test_file {

	local file="$1"
	local autorun="$2"
	local prefix="$3"
	local inc_fcts="$4"
	local exc_fcts="$5"

	# Set default values
	[[ -n $autorun ]] || autorun=1
	[[ -n $prefix ]] || prefix="$_tt_default_fct_prefix"

	lg_debug 1 "Running tests in file \"$file\"."

	_TT_FCTS_RUN_IN_TEST_FILE=()
	source "$file"

	# Run all test_.* functions not run explicitly by test_that
	if [[ -n $autorun ]] ; then
		for fct in $(grep '^ *\(function \+'$prefix'[^ ]\+\|'$prefix'[^ ]\+()\) *{' "$file" | sed 's/^ *\(function \+\)\?\('$prefix'[^ {(]\+\).*$/\2/') ; do

			# Ignore some reserved names
			[[ $fct == tt_test_context || $fct == tt_test_that ]] && continue

			# Run function
			[[ " ${_TT_FCTS_RUN_IN_TEST_FILE[*]} " == *" $fct "* ]] || \
				tt_test_that "" "$fct" "$inc_fcts" "$exc_fcts"
		done
	fi

	return 0
}

function _tt_print_end_report {

	if [[ $_TT_ERR_NUMBER -gt 0 ]] ; then
		echo '================================================================'
		echo "$_TT_ERR_NUMBER error(s) encountered."

		# Loop on all errors
		for ((i = 0 ; i < _TT_ERR_NUMBER ; ++i)) ; do
			_tt_print_error $((i+1)) "${_TT_ERR_MSGS[$i]}" \
				"${_TT_ERR_STDERR_FILES[$i]}"
		done
	fi
}

output_progress() {
# Output the progress of a command, by taking both stdout and stderr of the
# command and replace each line by a dot character.
# This function is useful while some part of the test code takes much time
# and use does not get any feedback.
# It is also particularly essential with Travis-CI, which aborts the test
# if no output has been seen for the last 10 minutes.
	"$@" 2>&1 | while read line ; do echo -n . ; done
}

function tt_expect_success_in_n_tries {

	local n=$1
	shift
	local cmd="$*"

	# Try to run the command
	for ((i = 0 ; i < n ; ++i)) ; do
		( "$@" >&2 )
		err=$?
		[[ $err == 0 ]] && break
	done

	# Failure
	if [[ $err -gt 0 ]] ; then
		rt_print_call_stack >&2
		echo "Command \"$cmd\" failed $n times." >&2
		return 1
	fi

	echo -n .
}

function tt_expect_success {

	local cmd="$*"

	( "$@" >&2 )
	local status=$?

	if [[ $status -gt 0 ]] ; then
		rt_print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		return 1
	fi

	echo -n .

	return 0
}

function tt_expect_failure {

	local cmd="$*"

	( "$@" >&2 )

	if [ $? -eq 0 ] ; then
		rt_print_call_stack >&2
		echo "Command \"$cmd\" was successful while expecting failure." >&2
		return 1
	fi

	echo -n .
}

function tt_expect_status {

	local expected_status="$1"
	shift
	local cmd="$*"

	( "$@" >&2 )
	local actual_status=$?

	if [[ $actual_status -ne $expected_status ]] ; then
		rt_print_call_stack >&2
		echo "Command \"$cmd\" failed with status $actual_status, but " \
			"expected status $expected_status." >&2
		return 2
	fi

	echo -n .
}

function tt_expect_empty_output {

	local cmd="$*"
	local output=
	local tmpfile=$(mktemp -t $PROGNAME.XXXXXX)

	( "$@" >"$tmpfile" )
	local status=$?

	output=$(cat "$tmpfile")
	unlink "$tmpfile"

	if [[ $status -ne 0 ]] ; then
		rt_print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		return 1
	elif [[ -n $output ]] ; then
		rt_print_call_stack >&2
		echo "Output of \"$cmd\" is not empty. Output: \"$output\"." >&2
		return 2
	fi

	echo -n .
}

function tt_expect_non_empty_output {

	local cmd="$*"
	local empty=
	local tmpfile=$(mktemp -t $PROGNAME.XXXXXX)

	( "$@" >"$tmpfile" )
	local status=$?

	[[ -s "$tmpfile" ]] || empty=1
	unlink "$tmpfile"

	if [[ $status -ne 0 ]] ; then
		rt_print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		return 1
	elif [[ -n $empty ]] ; then
		rt_print_call_stack >&2
		echo "Output of \"$cmd\" is empty." >&2
		return 2
	fi

	echo -n .
}

function _tt_expect_output_op {

	local op="$1"
	local expected_output="$2"
	shift 2
	local cmd="$*"
	local tmpfile=$(mktemp -t $PROGNAME.XXXXXX)

	( "$@" >"$tmpfile" )
	local status=$?
	local output=$(cat "$tmpfile")
	rm "$tmpfile"

	if [[ $status -ne 0 ]] ; then
		rt_print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		return 1
	elif [[ $op == eq && "$expected_output" != "$output" ]] ; then
		rt_print_call_stack >&2
		echo "Output of \"$cmd\" is wrong. Expected \"$expected_output\". Got \"$output\"." >&2
		return 2
	elif [[ $op == ne && "$expected_output" == "$output" ]] ; then
		rt_print_call_stack >&2
		echo "Output of \"$cmd\" is wrong. Expected something different from \"$expected_output\"." >&2
		return 3
	elif [[ $op == re ]] && ! egrep "$expected_output" >/dev/null <<<"$output" ; then
		rt_print_call_stack >&2
		echo "Output of \"$cmd\" is wrong. Expected \"$expected_output\". Got \"$output\"." >&2
		return 4
	fi

	echo -n .
}

function tt_expect_output_eq {
	_tt_expect_output_op 'eq' "$@"
	return $?
}

function tt_expect_output_re {
	_tt_expect_output_op 're' "$@"
	return $?
}

function tt_expect_output_ne {
	_tt_expect_output_op 'ne' "$@"
	return $?
}

function _tt_expect_output_esc_op {

	local op="$1"
	local expected_output="$2"
	shift 2
	local cmd="$*"
	local tmpfile=$(mktemp -t $PROGNAME.XXXXXX)
	local tmpfile2=$(mktemp -t $PROGNAME.XXXXXX)

	( "$@" >"$tmpfile" )
	local status=$?

	echo -ne "$expected_output" >"$tmpfile2"

	if [[ $status -ne 0 ]] ; then
		rt_print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		rm "$tmpfile" "$tmpfile2"
		return 1
	elif [[ $op == eq ]] && ! diff -q "$tmpfile" "$tmpfile2" ; then
		rt_print_call_stack >&2
		echo -n "Output of \"$cmd\" is wrong. Expected \"$expected_output\". Got \"" >&2
		cat $tmpfile >&2
		echo "\"." >&2
		rm "$tmpfile" "$tmpfile2"
		return 2
	elif [[ $op == ne ]] && diff -q "$tmpfile" "$tmpfile2" ; then
		rt_print_call_stack >&2
		echo -n "Output of \"$cmd\" is wrong. Expected something different from \"$expected_output\"." >&2
		rm "$tmpfile" "$tmpfile2"
		return 3
	fi

	rm "$tmpfile" "$tmpfile2"
	echo -n .
}

function tt_expect_output_esc_ne {
	_tt_expect_output_esc_op 'ne' "$@"
	return $?
}

function tt_expect_output_esc_eq {
	_tt_expect_output_esc_op 'eq' "$@"
	return $?
}

function tt_expect_output_nlines_eq {

	local n="$1"
	shift
	local cmd="$*"
	local tmpfile=$(mktemp -t $PROGNAME.XXXXXX)

	( "$@" >"$tmpfile" )
	local status=$?

	local nlines=$(awk 'END { print NR }' "$tmpfile")
	unlink "$tmpfile"

	if [[ $status -ne 0 ]] ; then
		rt_print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		return 1
	elif [[ $nlines -ne $n ]] ; then
		rt_print_call_stack >&2
		echo "Output of \"$cmd\" contains $nlines lines, not $n." >&2
		return 2
	fi

	echo -n .
}

function tt_expect_output_nlines_ge {

	local n="$1"
	shift
	local cmd="$*"
	local tmpfile=$(mktemp -t $PROGNAME.XXXXXX)

	( "$@" >"$tmpfile" )
	local status=$?

	local nlines=$(wc -l <"$tmpfile")
	unlink "$tmpfile"

	if [[ $status -ne 0 ]] ; then
		rt_print_call_stack >&2
		echo "Command \"$cmd\" failed with status $status." >&2
		return 1
	elif [[ ! $nlines -ge $n ]] ; then
		rt_print_call_stack >&2
		echo "Output of \"$cmd\" contains less than $n lines. It contains $nlines lines." >&2
		return 2
	fi

	echo -n .
}

function tt_expect_csv_has_columns {

	local file=$1
	local sep=$2
	local expected_cols=$3

	# Get columns
	cols=$(tf_csv_get_col_names $file $sep 0 1)

	# Loop on all expected columns
	for c in $expected_cols ; do
		if [[ " $cols " != *" $c "* && " $cols " != *" \"$c\" "* ]] ; then
			rt_print_call_stack >&2
			echo "Column \"$c\" cannot be found inside columns of file \"$file\"." >&2
			echo "Columns of file \"$file\" are: $cols." >&2
			return 1
		fi
	done

	echo -n .
}

function tt_expect_csv_not_has_columns {

	local file=$1
	local sep=$2
	local expected_cols=$3

	# Get columns
	cols=$(tf_csv_get_col_names $file $sep 0 1)

	# Loop on all expected columns
	for c in $expected_cols ; do
		if [[ " $cols " == *" $c "* || " $cols " == *" \"$c\" "* ]] ; then
			rt_print_call_stack >&2
			echo "Column \"$c\" has been found inside columns of file \"$file\"." >&2
			echo "Columns of file \"$file\" are: $cols." >&2
			return 1
		fi
	done

	echo -n .
}

function tt_expect_csv_identical_col_values {

	local col=$1
	local file1=$2
	local file2=$3
	local sep=$4

	col1=$(tf_csv_get_col_index $file1 $sep $col)
	tt_expect_num_gt $col1 0 "\"$file1\" does not contain column $col."
	col2=$(tf_csv_get_col_index $file2 $sep $col)
	tt_expect_num_gt $col2 0 "\"$file2\" does not contain column $col."
	ncols_file1=$(tf_csv_get_nb_cols $file1 $sep)
	((col2 = col2 + ncols_file1))
	ident=$(paste $file1 $file2 | awk 'BEGIN{FS="'$sep'";eq=1}{if ($'$col1' != $'$col2') {eq=0}}END{print eq}')
	if [[ $ident -ne 1 ]] ; then
		rt_print_call_stack >&2
		echo "Files \"$file1\" and \"$file2\" do not have the same values in column \"$col\"." >&2
		return 1
	fi
}

function tt_expect_csv_same_col_names {

	local file1=$1
	local file2=$2
	local sep=$3
	local nbcols=$4
	local remove_quotes=$5

	cols1=$(tf_csv_get_col_names $file1 $sep $nbcols $remove_quotes)
	cols2=$(tf_csv_get_col_names $file2 $sep $nbcols $remove_quotes)
	if [[ $cols1 != $cols2 ]] ; then
		rt_print_call_stack >&2
		echo "Column names of files \"$file1\" and \"$file2\" are different." >&2
		[[ -n $nbcols ]] && echo "Comparison on the first $nbcols columns only." >&2
		echo "Columns of file \"$file1\" are: $cols1." >&2
		echo "Columns of file \"$file2\" are: $cols2." >&2
		return 1
	fi

	echo -n .
}

function tt_expect_csv_float_col_equals {

	local file=$1
	local sep=$2
	local col=$3
	local val=$4
	local tol=$5

	col_index=$(tf_csv_get_col_index $file $sep $col)
	ident=$(awk 'function abs(v) { return v < 0 ? -v : v }BEGIN{FS="'$sep'";eq=1}{if (NR > 1 && abs($'$col_index' - '$val') > '$tol') {eq=0}}END{print eq}' $file)

	[[ $ident -eq 1 ]] || return 1
}

function tt_expect_empty_file {

	local file="$1"
	local msg="$2"

	if [[ ! -f $file || -s $file ]] ; then
		rt_print_call_stack >&2
		echo "\"$file\" does not exist, is not a file or is not empty. $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_non_empty_file {

	local file="$1"
	local msg="$2"

	if [[ ! -f $file || ! -s $file ]] ; then
		rt_print_call_stack >&2
		echo "\"$file\" does not exist, is not a file or is empty. $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_same_files {

	local file1="$1"
	local file2="$2"

	tt_expect_file "$file1" || return 2
	tt_expect_file "$file2" || return 3

	if ! diff -q "$file1" "$file2" >/dev/null ; then
		rt_print_call_stack >&2
		echo "Files \"$file1\" and \"$file2\" differ." >&2
		return 1
	fi

	echo -n .
}

function tt_expect_same_number_of_rows {

	local file1=$1
	local file2=$2

	if [[ $(tf_get_nb_rows "$file1") -ne $(tf_get_nb_rows "$file2") ]] ; then
		rt_print_call_stack >&2
		echo "\"$file1\" and \"$file2\" do not have the same number of rows." >&2
		return 1
	fi

	echo -n .
}

function tt_expect_no_duplicated_row {

	local file=$1

	nrows=$(cat $file | wc -l)
	n_uniq_rows=$(sort -u $file | wc -l)
	[[ $nrows -eq $n_uniq_rows ]] || return 1
}

function tt_expect_str_null {

	local v=$1
	local msg="$2"

	if [[ -n $v ]] ; then
		rt_print_call_stack >&2
		echo "String \"$v\" is not null ! $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_str_not_null {

	local v=$1
	local msg="$2"

	if [[ -z $v ]] ; then
		rt_print_call_stack >&2
		echo "String is null ! $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_str_eq {

	local a=$1
	local b=$2
	local msg="$3"

	if [[ $a != $b ]] ; then
		rt_print_call_stack >&2
		echo "\"$a\" == \"$b\" not true ! $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_str_ne {

	local a=$1
	local b=$2
	local msg="$3"

	if [[ $a == $b ]] ; then
		rt_print_call_stack >&2
		echo "\"$a\" != \"$b\" not true ! $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_str_re {

	local str="$1"
	local re="$2"
	local msg="$3"

	local s=$(echo "$str" | egrep "$re")
	if [[ -z $s ]] ; then
		rt_print_call_stack >&2
		echo "\"$str\" not matched by regular expression \"$re\" ! $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_num_eq {

	local a=$1
	local b=$2
	local msg="$3"

	if [[ ! $a -eq $b ]] ; then
		rt_print_call_stack >&2
		echo "$a == $b not true ! $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_num_ne {

	local a=$1
	local b=$2
	local msg="$3"

	if [[ ! $a -ne $b ]] ; then
		rt_print_call_stack >&2
		echo "$a != $b not true ! $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_num_le {

	local a=$1
	local b=$2
	local msg="$3"

	if [[ ! $a -le $b ]] ; then
		rt_print_call_stack >&2
		echo "$a <= $b not true ! $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_num_gt {

	local a=$1
	local b=$2
	local msg="$3"

	if [[ ! $a -gt $b ]] ; then
		rt_print_call_stack >&2
		echo "$a > $b not true ! $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_def_env_var {

	local varname="$1"
	local msg="$2"

	if [[ -z "${!varname}" ]] ; then
		rt_print_call_stack >&2
		echo "Env var $varname is not defined or is empty ! $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_no_path {

	local path="$1"
	local msg="$2"

	if [[ -e $path ]] ; then
		rt_print_call_stack >&2
		echo "\"$path\" exists. $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_folder {

	local folder="$1"
	local msg="$2"

	if [[ ! -d $folder ]] ; then
		rt_print_call_stack >&2
		echo "\"$folder\" does not exist or is not a folder. $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_file {

	local file="$1"
	local msg="$2"

	if [[ ! -f $file ]] ; then
		rt_print_call_stack >&2
		echo "\"$file\" does not exist or is not a file. $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_symlink {

	local symlink="$1"
	local pointed_path="$2"
	local msg="$3"

	if [[ ! -h $symlink ]] ; then
		rt_print_call_stack >&2
		echo "\"$symlink\" does not exist or is not a symbolic link. $msg" >&2
		return 1
	else
		local path=$(realpath "$symlink")
		local real_pointed_path=$(realpath "$pointed_path")
		if [[ $path != $real_pointed_path ]] ; then
			rt_print_call_stack >&2
			echo "Symbolic link \"$symlink\" does not point to \"$pointed_path\" but to \"$path\". $msg" >&2
			return 1
		fi
	fi

	echo -n .
}

function tt_expect_folder_is_writable {

	local folder="$1"
	local msg="$2"
	local file="$folder/.___testthat_test_file___"

	if ! touch "$file" ; then
		rt_print_call_stack >&2
		echo "Folder \"$folder\" is not writable. $msg" >&2
		return 1
	fi

	unlink "$file"
	echo -n .
}

function tt_expect_other_files_in_folder {

	local folder="$1"
	local files_regex="$2"
	local msg="$3"

	# List files in folder
	prevdir=$(pwd)
	cd "$folder"
	files=$(ls -1 | egrep -v "$files_regex")
	cd "$prevdir"
	if [[ -z $files ]] ; then
		rt_print_call_stack >&2
		echo "No files, not matching \"$files_regex\", were found inside folder \"$folder\". $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_other_files_in_tree {

	local folder="$1"
	local files_regex="$2"
	local msg="$3"

	# List files in folder
	prevdir=$(pwd)
	files=$(find "$folder" -type f | xargs -n 1 basename | egrep -v "$files_regex")
	if [[ -z $files ]] ; then
		rt_print_call_stack >&2
		echo "No files, not matching \"$files_regex\", were found inside folder tree \"$tree\". $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_no_other_files_in_tree {

	local folder="$1"
	local files_regex="$2"
	local msg="$3"

	# List files in folder
	files_matching=$(find "$folder" -type f -printf '"%p"\n' | xargs -n 1 basename | egrep "$files_regex")
	files_not_matching=$(find "$folder" -type f -printf '"%p"\n' | xargs -n 1 basename | egrep -v "$files_regex")
	if [[ -z $files_matching ]] ; then
		rt_print_call_stack >&2
		echo "No files matching \"$files_regex\" were found inside folder tree \"$folder\". $msg" >&2
		return 1
	fi
	if [[ -n $files_not_matching ]] ; then
		rt_print_call_stack >&2
		echo "Files, not matching \"$files_regex\", were found inside folder \"$folder\": $files_not_matching. $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_no_other_files_in_folder {

	local folder="$1"
	local files_regex="$2"
	local msg="$3"

	# List files in folder
	prevdir=$(pwd)
	cd "$folder"
	files_matching=$(ls -1 | egrep "$files_regex")
	files_not_matching=$(ls -1 | egrep -v "$files_regex")
	cd "$prevdir"
	if [[ -z $files_matching ]] ; then
		rt_print_call_stack >&2
		echo "No files matching \"$files_regex\" were found inside folder \"$folder\". $msg" >&2
		return 1
	fi
	if [[ -n $files_not_matching ]] ; then
		rt_print_call_stack >&2
		echo "Files, not matching \"$files_regex\", were found inside folder \"$folder\". $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_files_in_tree {

	local folder="$1"
	local files_regex="$2"
	local msg="$3"

	# List files in folder
	prevdir=$(pwd)
	files=$(find "$folder" -type f | xargs -n 1 basename | egrep "$files_regex")
	if [[ -z $files ]] ; then
		rt_print_call_stack >&2
		echo "No files matching \"$files_regex\" were found inside folder tree \"$folder\". $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_files_in_folder {

	local folder="$1"
	local files_regex="$2"
	local msg="$3"

	# List files in folder
	prevdir=$(pwd)
	cd "$folder"
	files=$(ls -1 | egrep "$files_regex")
	cd "$prevdir"
	if [[ -z $files ]] ; then
		rt_print_call_stack >&2
		echo "No files matching \"$files_regex\" were found inside folder \"$folder\". $msg" >&2
		return 1
	fi

	echo -n .
}

function tt_expect_same_folders {

	local folder1="$1"
	local folder2="$2"

	tt_expect_folder "$folder1" || return 2
	tt_expect_folder "$folder2" || return 3

	if ! diff -r -q "$folder1" "$folder2" >/dev/null ; then
		rt_print_call_stack >&2
		echo "Folders \"$folder1\" and \"$folder2\" differ." >&2
		return 1
	fi

	echo -n .
}

## Run tests on files and folder.
function tt_run_tests {

	local pattern="$1"
	local inc_files="$2"
	local autorun="$3"
	local fct_prefix="$4"
	local inc_fcts="$5"
	local exc_fcts="$6"
	shift 6
	# Files and folders: $*

	# Set default values
	[[ -n $pattern ]] || pattern="$_TT_DEFAULT_FILE_PATTERN"
	[[ -n $autorun ]] || autorun=1
	[[ -n $prefix ]] || prefix="$_tt_default_fct_prefix"

	lg_debug 1 "Running tests of following files and folders: $*."
	lg_debug 1 "File pattern: $pattern"

	# Loop on folders and files to test
	for e in "$@" ; do

		[[ -f $e || -d $e ]] || \
			lg_error "\"$e\" is neither a file nor a folder."

		# File
		[[ -f $e ]] && tt_run_test_file "$e" "$autorun" "$fct_prefix" \
			"$inc_fcts" "$exc_fcts"

		# Folder
		if [[ -d $e ]] ; then
			lg_debug 1 "Looking for test files in folder \"$e\"."
			local tmp_file=$(mktemp -t $PROGNAME.XXXXXX)
			ls -d1 $e/* | sort >$tmp_file
			while read f ; do

				lg_debug 1 "Check if file "$f" is a test file."

				# Check file pattern
				local filename=$(basename "$f")
				[[ -f $f && $filename =~ ^$pattern$ ]] || continue

				# Filter
				lg_debug 1 "Filtering filename \"$filename\" on list of files"\
					"to include \"$inc_files\"."
				[[ -z $inc_files || ",$inc_files," == *",$filename,"* ]] \
					|| continue

				# Run tests in file
				lg_debug 1 "Run test file \"$f\"."
				tt_run_test_file "$f" "$autorun" "$fct_prefix" "$inc_fcts" \
					"$exc_fcts"
			done <$tmp_file
		fi

	done

	return 0
}

