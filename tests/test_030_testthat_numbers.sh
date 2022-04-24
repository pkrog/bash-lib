tt_context "Testing testthat library"

function test_expect_num_ne {
	tt_expect_failure tt_expect_num_ne 0 0 "Message" || return 1
	tt_expect_failure tt_expect_num_ne 5 5 "Message" || return 1
	tt_expect_success tt_expect_num_ne 0 1 "Message" || return 1
}

function test_expect_num_eq {
	tt_expect_success tt_expect_num_eq 0 0 "Message" || return 1
	tt_expect_success tt_expect_num_eq 5 5 "Message" || return 1
	tt_expect_failure tt_expect_num_eq 0 1 "Message" || return 1
}

function test_expect_num_le {
	tt_expect_success tt_expect_num_le 0 0 "Message" || return 1
	tt_expect_success tt_expect_num_le 0 1 "Message" || return 1
	tt_expect_success tt_expect_num_le 1 10 "Message" || return 1
	tt_expect_success tt_expect_num_le 10 10 "Message" || return 1
	tt_expect_failure tt_expect_num_le 1 0 "Message" || return 1
}

function test_expect_num_gt {
	tt_expect_success tt_expect_num_gt 1 0 "Message" || return 1
	tt_expect_failure tt_expect_num_gt 0 1 "Message" || return 1
	tt_expect_failure tt_expect_num_gt 0 0 "Message" || return 1
}
