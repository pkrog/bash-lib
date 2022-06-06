SCRIPT_DIR=$(dirname $BASH_SOURCE)
source "$SCRIPT_DIR/../actionloop.sh"

tt_context "Testing action loop library"

function action1 {
	TESTVAR+=action1
	return 0
}

function action2 {
	TESTVAR+=action2
	return 0
}

function action3 {
	TESTVAR+=action3
	return 0
}

function test_no_action {
	al_reset || return 1
	tt_expect_failure al_run_actions "foo" || return 1
}

function test_one_action {
	al_reset || return 1
	al_def_action "action1" || return 1
	TESTVAR=
	al_run_actions "action1" || return 1
	tt_expect_str_eq "$TESTVAR" action1 || return 1
	tt_expect_failure al_run_actions "foo" || return 1
}

function test_custom_fct_name {
	al_reset || return 1
	al_def_action "myaction" "action1" || return 1
	TESTVAR=
	al_run_actions "myaction" || return 1
	tt_expect_str_eq "$TESTVAR" action1 || return 1
	tt_expect_failure al_run_actions "action1" || return 1
}

function test_two_actions {
	al_reset || return 1
	al_def_action "action1" || return 1
	al_def_action "action2" || return 1
	tt_expect_failure al_run_actions "foo" || return 1
	TESTVAR=
	al_run_actions "action1" || return 1
	tt_expect_str_eq "$TESTVAR" action1 || return 1
	TESTVAR=
	al_run_actions "action2" || return 1
	tt_expect_str_eq "$TESTVAR" action2 || return 1
	TESTVAR=
	al_run_actions "action1" "action2" || return 1
	tt_expect_str_eq "$TESTVAR" action1action2 || return 1
	TESTVAR=
	al_run_actions "action2" "action1" || return 1
	tt_expect_str_eq "$TESTVAR" action2action1 || return 1
}

function test_actions_ordering {
	al_reset || return 1
	al_def_action "action1" || return 1
	al_def_action "action2" || return 1
	tt_expect_failure al_def_actions_order "foo" || return 1
	al_def_actions_order "action2" "action1" || return 1
	tt_expect_failure al_run_actions "foo" || return 1
	TESTVAR=
	al_run_actions "action1" || return 1
	tt_expect_str_eq "$TESTVAR" action1 || return 1
	TESTVAR=
	al_run_actions "action2" || return 1
	tt_expect_str_eq "$TESTVAR" action2 || return 1
	TESTVAR=
	al_run_actions "action1" "action2" || return 1
	tt_expect_str_eq "$TESTVAR" action2action1 || return 1
	TESTVAR=
	al_run_actions "action2" "action1" || return 1
	tt_expect_str_eq "$TESTVAR" action2action1 || return 1
}

function test_action_dep {
	al_reset || return 1

	# 1 co-action
	al_def_action "action1" || return 1
	tt_expect_failure al_def_co_actions "action2" "action1" || return 1
	al_def_action "action2" || return 1
	al_def_co_actions "action2" "action1" || return 1
	al_def_actions_order "action1" "action2" || return 1
	TESTVAR=
	al_run_actions "action1" || return 1
	tt_expect_str_eq "$TESTVAR" action1 || return 1
	TESTVAR=
	al_run_actions "action2" || return 1
	tt_expect_str_eq "$TESTVAR" action1action2 || return 1

	# 2 co-actions
	al_def_action "action3" || return 1
	al_def_co_actions "action2" "action1" "action3" || return 1
	al_def_actions_order "action1" "action2" "action3" || return 1
	TESTVAR=
	al_run_actions "action1" || return 1
	tt_expect_str_eq "$TESTVAR" action1 || return 1
	TESTVAR=
	al_run_actions "action3" || return 1
	tt_expect_str_eq "$TESTVAR" action3 || return 1
	TESTVAR=
	al_run_actions "action2" || return 1
	tt_expect_str_eq "$TESTVAR" action1action2action3 || return 1
}
