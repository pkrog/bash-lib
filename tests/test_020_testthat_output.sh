tt_context "Testing testthat library"

function test_empty_output {
	tt_expect_success tt_expect_empty_output echo -n || return 1
	tt_expect_failure tt_expect_empty_output echo ABC || return 1
}

function test_non_empty_output {
	tt_expect_success tt_expect_non_empty_output echo ABC || return 1
	tt_expect_failure tt_expect_non_empty_output echo -n || return 1
}

function test_output_eq {
	cr="
"
	tt_expect_success tt_expect_output_eq "" echo -n || return 1
	tt_expect_success tt_expect_output_eq "ABC" echo -n ABC || return 1
	tt_expect_failure tt_expect_output_eq "1" echo -n || return 1
	tt_expect_success tt_expect_output_eq 'A\nBC' echo -n 'A\nBC' || return 1
	tt_expect_success tt_expect_output_eq "A${cr}BC" echo -ne "A\nBC" || return 1
	tt_expect_failure tt_expect_output_eq 'A\nBC' echo -ne 'A\nBC' || return 1
	tt_expect_success tt_expect_output_eq "ABC" echo ABC || return 1
	tt_expect_success tt_expect_output_eq "" echo || return 1
}

function test_output_ne {
	cr="
"
	tt_expect_failure tt_expect_output_ne "" echo -n || return 1
	tt_expect_failure tt_expect_output_ne "ABC" echo -n ABC || return 1
	tt_expect_failure tt_expect_output_ne 'A\nBC' echo -n 'A\nBC' || return 1
	tt_expect_failure tt_expect_output_ne "A${cr}BC" echo -ne "A\nBC" || return 1
	tt_expect_failure tt_expect_output_ne "ABC" echo ABC || return 1
	tt_expect_failure tt_expect_output_ne "" echo || return 1
	tt_expect_success tt_expect_output_ne "1" echo -n || return 1
	tt_expect_success tt_expect_output_ne 'A\nBC' echo -ne 'A\nBC' || return 1
}

function test_output_esc_eq {
	tt_expect_success tt_expect_output_esc_eq "" echo -n || return 1
	tt_expect_success tt_expect_output_esc_eq "ABC" echo -n ABC || return 1
	tt_expect_failure tt_expect_output_esc_eq "1" echo -n || return 1
	tt_expect_success tt_expect_output_esc_eq "A\nBC" echo -ne "A\nBC" || return 1
	tt_expect_success tt_expect_output_esc_eq "ABC\n" echo ABC || return 1
	tt_expect_success tt_expect_output_esc_eq "\n" echo || return 1
}

function test_output_esc_ne {
	tt_expect_failure tt_expect_output_esc_ne "" echo -n || return 1
	tt_expect_failure tt_expect_output_esc_ne "ABC" echo -n ABC || return 1
	tt_expect_success tt_expect_output_esc_ne "1" echo -n || return 1
	tt_expect_failure tt_expect_output_esc_ne "A\nBC" echo -ne "A\nBC" || return 1
	tt_expect_failure tt_expect_output_esc_ne "ABC\n" echo ABC || return 1
	tt_expect_failure tt_expect_output_esc_ne "\n" echo || return 1
}

function test_output_nlines_eq {
	tt_expect_success tt_expect_output_nlines_eq 0 echo -n || return 1
	tt_expect_success tt_expect_output_nlines_eq 1 echo ABC || return 1
	tt_expect_success tt_expect_output_nlines_eq 2 echo -e "A\nBC" || return 1
	tt_expect_success tt_expect_output_nlines_eq 3 echo -e "A\nB\nC" || return 1
	tt_expect_failure tt_expect_output_nlines_eq 2 echo ABC || return 1
	tt_expect_failure tt_expect_output_nlines_eq 0 echo ABC || return 1
	tt_expect_failure tt_expect_output_nlines_eq 1 echo -n || return 1
}

function test_output_nlines_ge {
	tt_expect_success tt_expect_output_nlines_ge 0 echo -n || return 1
	tt_expect_failure tt_expect_output_nlines_ge 1 echo -n || return 1
	tt_expect_success tt_expect_output_nlines_ge 1 echo ABC || return 1
	tt_expect_success tt_expect_output_nlines_ge 0 echo ABC || return 1
	tt_expect_success tt_expect_output_nlines_ge 0 echo -e "A\nBC" || return 1
	tt_expect_success tt_expect_output_nlines_ge 1 echo -e "A\nBC" || return 1
	tt_expect_success tt_expect_output_nlines_ge 2 echo -e "A\nBC" || return 1
	tt_expect_success tt_expect_output_nlines_ge 3 echo -e "A\nB\nC" || return 1
	tt_expect_failure tt_expect_output_nlines_ge 2 echo ABC || return 1
	tt_expect_failure tt_expect_output_nlines_ge 3 echo ABC || return 1
	tt_expect_failure tt_expect_output_nlines_ge 3 echo -e "A\nBC" || return 1
	tt_expect_failure tt_expect_output_nlines_ge 4 echo -e "A\nB\nC" || return 1
}

function test_output_re {
	tt_expect_success tt_expect_output_re ".*" echo -n || return 1
	tt_expect_success tt_expect_output_re "A.C" echo -n ABC || return 1
	tt_expect_failure tt_expect_output_re "." echo -n || return 1
	tt_expect_failure tt_expect_output_re "^[B-C]+" echo -n ABC || return 1
	tt_expect_success tt_expect_output_re "[A-C]*" echo -n ABC || return 1
}
