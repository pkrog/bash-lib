tt_context "Testing testthat library"

OUTPUT_DIR="$(dirname $BASH_SOURCE)/output"
mkdir -p "$OUTPUT_DIR"
NTRIES_FILE="$OUTPUT_DIR/ntries.txt"

function test_success {

	tt_expect_success tt_expect_success true  || return 1
	tt_expect_success tt_expect_success exit 0 || return 1

	tt_expect_failure tt_expect_success false || return 1
	tt_expect_failure tt_expect_success exit 1 || return 1
}

function command_n_tries {

	local i=$(sed 's/ .*$//' "$NTRIES_FILE")
	local n=$(sed 's/^.* //' "$NTRIES_FILE")

	((++i))
	echo "$i $n" >"$NTRIES_FILE"

	[[ $i -eq $n ]] || return 1
}

function test_expect_success_in_n_tries {

	echo "0 3" >"$NTRIES_FILE"
	tt_expect_success_in_n_tries 3 command_n_tries || return 1
}

function cmd_with_status {
	local status=$1
	return $1
}

function test_expect_failure {

	tt_expect_success tt_expect_failure false || return 1
	tt_expect_success tt_expect_failure exit 1 || return 1
	tt_expect_success tt_expect_failure exit 2 || return 1
	tt_expect_success tt_expect_failure cmd_with_status 2 || return 1

	tt_expect_failure tt_expect_failure true || return 1
	tt_expect_failure tt_expect_failure exit 0 || return 1
}

function test_expect_status {

	tt_expect_success tt_expect_status 5 cmd_with_status 5 || return 1
	tt_expect_success tt_expect_status 0 exit 0 || return 1
	tt_expect_success tt_expect_status 1 exit 1 || return 1
	tt_expect_success tt_expect_status 2 exit 2 || return 1

	tt_expect_failure tt_expect_status 1 exit 0 || return 1
	tt_expect_failure tt_expect_status 0 exit 1 || return 1
}
