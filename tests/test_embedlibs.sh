SCRIPT_DIR=$(dirname $BASH_SOURCE)
APP="$SCRIPT_DIR/../embedlibs"
RES_DIR="$SCRIPT_DIR/res/embedlibs"
OUTPUT_DIR="$SCRIPT_DIR/output/embedlibs"
mkdir -p "$OUTPUT_DIR"

test_context "Testing embedlibs tool"

function test_embedlibs {

	local out_file="app1_with_embedded_libs.sh"

	$APP -l "$RES_DIR/bash-lib" "$RES_DIR/app1.sh" "$OUTPUT_DIR/$out_file"
	expect_same_files "$RES_DIR/$out_file" "$OUTPUT_DIR/$out_file"
}
