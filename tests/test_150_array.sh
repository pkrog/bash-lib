SCRIPT_DIR=$(dirname $BASH_SOURCE)
source "$SCRIPT_DIR/../array.sh"

tt_context "Testing array library"

function test_contains {
	tt_expect_failure ar_contains || return 1
	tt_expect_failure ar_contains a || return 1
	tt_expect_success ar_contains a a || return 1
	tt_expect_failure ar_contains a b || return 1
	tt_expect_success ar_contains a a a a || return 1
	tt_expect_success ar_contains a a b b || return 1
	tt_expect_success ar_contains a b a b || return 1
	tt_expect_success ar_contains a b b a || return 1
}
