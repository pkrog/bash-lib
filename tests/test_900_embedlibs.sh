SCRIPT_DIR=$(dirname $BASH_SOURCE)
APP="$SCRIPT_DIR/../embedlibs"
RES_DIR="$SCRIPT_DIR/res/embedlibs"
OUTPUT_DIR="$SCRIPT_DIR/output/embedlibs"
mkdir -p "$OUTPUT_DIR"

tt_context "Testing embedlibs tool"

function test_embedlibs_no_lib {

	local out_file="app0_with_embedded_libs.sh"

	$APP -gl "$RES_DIR/bash-lib" "$RES_DIR/app0.sh" "$OUTPUT_DIR/$out_file"
	tt_expect_same_files "$RES_DIR/$out_file" "$OUTPUT_DIR/$out_file"
}

function test_embedlibs_two_libs {

	local out_file="app1_with_embedded_libs.sh"

	$APP -gl "$RES_DIR/bash-lib" "$RES_DIR/app1.sh" "$OUTPUT_DIR/$out_file"
	tt_expect_same_files "$RES_DIR/$out_file" "$OUTPUT_DIR/$out_file"
}

function test_embedlibs_recursive {

	local out_file="app2_with_embedded_libs.sh"

	$APP -gl "$RES_DIR/bash-lib" "$RES_DIR/app2.sh" "$OUTPUT_DIR/$out_file"
	tt_expect_same_files "$RES_DIR/$out_file" "$OUTPUT_DIR/$out_file"
}

function test_embedlibs_recursive_with_duplication {

	local out_file="app3_with_embedded_libs.sh"

	$APP -gl "$RES_DIR/bash-lib" "$RES_DIR/app3.sh" "$OUTPUT_DIR/$out_file"
	tt_expect_same_files "$RES_DIR/$out_file" "$OUTPUT_DIR/$out_file"
}
