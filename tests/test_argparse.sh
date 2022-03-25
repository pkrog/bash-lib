# vi: se fdm=marker

SCRIPT_DIR=$(dirname $BASH_SOURCE)
source "$SCRIPT_DIR/../argparse.sh"

test_context "Testing argparse library"

# Test add_opt {{{1
################################################################

function test_opt {

	ap_reset_args || return 1
	expect_failure ap_read_args "-a" 2>/dev/null || return 1
	expect_failure ap_read_args "-g" 2>/dev/null || return 1
	expect_failure ap_read_args "-h" 2>/dev/null || return 1

	ap_add_debug_opt || return 1
	expect_failure ap_read_args "-a" 2>/dev/null || return 1
	expect_failure ap_read_args "-h" 2>/dev/null || return 1

	ap_add_help_opt || return 1

	ap_read_args "" || return 1
	expect_num_eq  $LG_DEBUG 0 || return 1

	ap_read_args "-g" || return 1
	expect_num_eq  $LG_DEBUG 1 || return 1

	LG_DEBUG=0
	ap_read_args "--debug" || return 1
	expect_num_eq  $LG_DEBUG 1 || return 1

	LG_DEBUG=0
	ap_read_args "-gg" || return 1
	expect_num_eq  $LG_DEBUG 2 || return 1

	LG_DEBUG=0
	ap_read_args "-ggg" || return 1
	expect_num_eq  $LG_DEBUG 3 || return 1

	ap_add_help_opt || return 1
	expect_success read_args "-h" || return 1
}

# Test add_pos {{{1
################################################################

function test_pos {

	ap_reset_args || return 1
	ap_add_pos_one SERVER "A server address." || return 1
	ap_read_args "my.addr" || return 1
	expect_str_eq $SERVER my.addr || return 1

	ap_reset_args || return 1
	ap_add_pos_n FILES 2 "Two valid files." || return 1
	ap_read_args "my.file1" "my.file2" || return 1
	expect_num_eq ${#FILES[@]} 2 || return 1
	expect_str_eq "${FILES[0]}" "my.file1" || return 1
	expect_str_eq "${FILES[1]}" "my.file2" || return 1

	unset FILES
	ap_reset_args || return 1
	ap_add_pos_max FILES "A list of files." || return 1
	ap_read_args f1 f2 f3 f4 || return 1
	expect_num_eq ${#FILES[@]} 4 || return 1
}
