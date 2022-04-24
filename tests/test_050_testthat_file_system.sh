tt_context "Testing testthat library"

TEST_DIR=$(dirname $BASH_SOURCE)
WORK_DIR="$TEST_DIR/output"
mkdir -p "$WORK_DIR"

function test_expect_file {

	local file="$WORK_DIR/afile"
	rm -f "$file"

	tt_expect_failure tt_expect_file "a_file_that_does_not_exist" "Message" || return 1
	tt_expect_failure tt_expect_file "$file" "Message" || return 1
	touch "$file"
	tt_expect_success tt_expect_file "$file" "Message" || return 1
	tt_expect_failure tt_expect_non_empty_file "$file" "Message" || return 1
	echo "Some content" > "$file"
	tt_expect_success tt_expect_non_empty_file "$file" "Message" || return 1
	rm "$file"
	tt_expect_failure tt_expect_file "$file" "Message" || return 1
}

function test_expect_symlink {

	local file=$(realpath "$WORK_DIR/afile")
	local symlink="$WORK_DIR/asymkink"
	rm -f "$symlink" "$file"

	tt_expect_failure tt_expect_symlink "$symlink" "$file" "Message" || return 1
	tt_expect_failure tt_expect_symlink "a_symlink_that_does_not_exist" "a_file_that_does_not_exist" "Message" || return 1
	touch "$file"
	tt_expect_success tt_expect_file "$file" "Message" || return 1
	tt_expect_failure tt_expect_symlink "file" "a_file_that_does_not_exist" "Message" || return 1
	ln -sf "$file" "$symlink"
	tt_expect_failure tt_expect_symlink "$symlink" "a_file_that_does_not_exist" "Message" || return 1
	tt_expect_success tt_expect_symlink "$symlink" "$file" "Message" || return 1
	rm "$symlink"
	rm "$file"
}

function test_expect_folder {

	local folder="$WORK_DIR/afolder"
	local file="$WORK_DIR/afile"

	rm -r "$folder"
	tt_expect_failure tt_expect_folder "$folder" "Message" || return 1

	mkdir -p "$folder"
	tt_expect_success tt_expect_folder "$folder" "Message" || return 1

	touch "$file"
	tt_expect_failure tt_expect_folder "$file" "Message" || return 1
}

function test_expect_folder_is_writable {

	local folder="$WORK_DIR/afolder"
	rm -r "$folder"
	mkdir -p "$folder"
	chmod a-w "$folder"
	tt_expect_failure tt_expect_folder_is_writable "$folder" "Message" "" return 1
	chmod u+w "$folder"
	tt_expect_success tt_expect_folder_is_writable "$folder" "Message" "" return 1
}

function test_expect_files_in_folder {
	local folder="$WORK_DIR/afolder"
	local file="$folder/afile.txt"

	rm -rf "$folder"
	mkdir "$folder"
	touch "$file"
	tt_expect_success tt_expect_files_in_folder "$folder" '^.*\.txt$' "Message" || return 1
	tt_expect_failure tt_expect_files_in_folder "$folder" '^.*\.csv$' "Message" || return 1
	rm -r "$folder"
}

function test_expect_no_other_files_in_folder {
	local folder="$WORK_DIR/afolder"
	local file="$folder/afile.txt"

	rm -rf "$folder"
	mkdir "$folder"
	touch "$file"
	tt_expect_success tt_expect_files_in_folder "$folder" '^.*\.txt$' "Message" || return 1
	tt_expect_success tt_expect_no_other_files_in_folder "$folder" '^.*\.txt$' "Message" || return 1
}

function test_expect_other_files_in_folder {
	local folder="$WORK_DIR/afolder"
	local file1="$folder/afile.txt"
	local file2="$folder/afile.csv"

	rm -rf "$folder"
	mkdir "$folder"
	touch "$file1"
	touch "$file2"
	tt_expect_success tt_expect_files_in_folder "$folder" '^.*\.csv$' "Message" || return 1
	tt_expect_success tt_expect_other_files_in_folder "$folder" '^.*\.txt$' "Message" || return 1
	tt_expect_failure tt_expect_no_other_files_in_folder "$folder" '^.*\.txt$' "Message" || return 1
}

function test_expect_files_in_tree {
	local folder="$WORK_DIR/afolder"
	local subfolder="$WORK_DIR/afolder/and_its_subfolder"

	rm -rf "$folder"
	mkdir -p "$subfolder"
	tt_expect_failure tt_expect_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	touch "$folder/a.txt"
	touch "$subfolder/another_file.txt"
	touch "$subfolder/another_file.tsv"
	tt_expect_success tt_expect_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	tt_expect_success tt_expect_files_in_tree "$folder" '^.*\.txt$' "Message" || return 1
	tt_expect_success tt_expect_files_in_tree "$folder" '^.*\.tsv$' "Message" || return 1
	tt_expect_failure tt_expect_files_in_tree "$folder" '^.*\.csv$' "Message" || return 1
}

function test_expect_no_other_files_in_tree {
	local folder="$WORK_DIR/afolder"
	local subfolder="$WORK_DIR/afolder/and_its_subfolder"

	rm -rf "$folder"
	mkdir -p "$subfolder"
	tt_expect_failure tt_expect_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	tt_expect_failure tt_expect_no_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	touch "$folder/a.txt"
	tt_expect_success tt_expect_no_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	tt_expect_failure tt_expect_no_other_files_in_tree "$folder" '^.*\.c.*$' "Message" || return 1
	touch "$subfolder/another_file.txt"
	touch "$subfolder/another_file.tsv"
	tt_expect_success tt_expect_no_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	tt_expect_failure tt_expect_no_other_files_in_tree "$folder" '^.*\.c.*$' "Message" || return 1
}

function test_expect_other_files_in_tree {
	local folder="$WORK_DIR/afolder"
	local subfolder="$WORK_DIR/afolder/and_its_subfolder"

	rm -rf "$folder"
	mkdir -p "$subfolder"
	touch "$folder/a.txt"
	touch "$subfolder/another_file.txt"
	touch "$subfolder/another_file.tsv"
	tt_expect_success tt_expect_no_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	tt_expect_failure tt_expect_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	tt_expect_failure tt_expect_files_in_tree "$folder" '^.*\.csv$' "Message" || return 1
	touch "$subfolder/another_file.csv"
	tt_expect_failure tt_expect_no_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
	tt_expect_success tt_expect_other_files_in_tree "$folder" '^.*\.t.*$' "Message" || return 1
}

function test_expect_same_folders {
	local folder_a="$WORK_DIR/folder_a"
	local folder_b="$WORK_DIR/folder_b"

	rm -r "$folder_a" "$folder_b"
	tt_expect_failure tt_expect_same_folders  "$folder_a" "$folder_b" || return 1

	mkdir -p "$folder_a"
	tt_expect_failure tt_expect_same_folders  "$folder_a" "$folder_b" || return 1
	tt_expect_failure tt_expect_same_folders  "$folder_b" "$folder_a" || return 1

	mkdir -p "$folder_b"
	tt_expect_success tt_expect_same_folders  "$folder_a" "$folder_b" || return 1

	touch "$folder_a/somefile"
	tt_expect_failure tt_expect_same_folders  "$folder_a" "$folder_b" || return 1

	touch "$folder_b/somefile"
	tt_expect_success tt_expect_same_folders  "$folder_a" "$folder_b" || return 1
}

function test_expect_output_nlines_eq {

	tt_expect_success tt_expect_output_nlines_eq 0 echo -n "" || return 1
	tt_expect_failure tt_expect_output_nlines_eq 1 echo -n "" || return 1
	tt_expect_failure tt_expect_output_nlines_eq 0 echo "" || return 1
	tt_expect_success tt_expect_output_nlines_eq 1 echo "" || return 1
	tt_expect_failure tt_expect_output_nlines_eq 0 echo -n "ABC" || return 1
	tt_expect_success tt_expect_output_nlines_eq 1 echo -n "ABC" || return 1
	tt_expect_failure tt_expect_output_nlines_eq 2 echo -n "ABC" || return 1
	tt_expect_failure tt_expect_output_nlines_eq 0 echo "ABC" || return 1
	tt_expect_success tt_expect_output_nlines_eq 1 echo "ABC" || return 1
	tt_expect_failure tt_expect_output_nlines_eq 2 echo "ABC" || return 1
	tt_expect_failure tt_expect_output_nlines_eq 0 echo -en "ABC\nDEF" || return 1
	tt_expect_failure tt_expect_output_nlines_eq 1 echo -en "ABC\nDEF" || return 1
	tt_expect_success tt_expect_output_nlines_eq 2 echo -en "ABC\nDEF" || return 1
	tt_expect_failure tt_expect_output_nlines_eq 3 echo -en "ABC\nDEF" || return 1
	tt_expect_failure tt_expect_output_nlines_eq 0 echo -e "ABC\nDEF" || return 1
	tt_expect_failure tt_expect_output_nlines_eq 1 echo -e "ABC\nDEF" || return 1
	tt_expect_success tt_expect_output_nlines_eq 2 echo -e "ABC\nDEF" || return 1
	tt_expect_failure tt_expect_output_nlines_eq 3 echo -e "ABC\nDEF" || return 1
}
