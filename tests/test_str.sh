SCRIPT_DIR=$(dirname $BASH_SOURCE)
source "$SCRIPT_DIR/../str.sh"

test_context "Testing string library"

function test_join {
	expect_str_eq "$(st_join)" "" || return 1
	expect_str_eq $(st_join ,) "" || return 1
	expect_str_eq $(st_join "" a) a || return 1
	expect_str_eq $(st_join , a) a || return 1
	expect_str_eq $(st_join , a b) a,b || return 1
	expect_str_eq $(st_join , a b c) a,b,c || return 1
	expect_str_eq $(st_join , ab) ab || return 1
	expect_str_eq $(st_join , ab c) ab,c || return 1
	expect_str_eq "$(st_join ', ' ab c)" "ab, c" || return 1
}
